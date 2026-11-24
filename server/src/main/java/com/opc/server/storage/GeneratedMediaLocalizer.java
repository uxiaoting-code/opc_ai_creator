package com.opc.server.storage;

import com.opc.server.ai.AiTaskResult;
import com.opc.server.entity.enums.TaskType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * 把第三方服务商返回的临时媒体 URL 下载到本地存储。
 *
 * <p>Flutter Web 使用 CanvasKit 加载网络图片时会受到浏览器 CORS 限制。
 * 火山 TOS 的签名图片 URL 可以在普通 img 标签和后台审核页显示，但不一定允许
 * Flutter Web 的图片加载器跨域读取，最终会进入 errorBuilder 显示默认图。
 * 同时第三方 URL 通常只有 24 小时有效期，也不能作为作品长期地址。
 *
 * <p>因此生成成功后必须先由后端下载到 /upload，再把稳定 URL 返回给用户端。
 */
@Service
public class GeneratedMediaLocalizer {

    private static final Logger log = LoggerFactory.getLogger(GeneratedMediaLocalizer.class);
    private static final long MAX_MEDIA_BYTES = 100L * 1024 * 1024;
    private static final Pattern EXTENSION_PATTERN =
            Pattern.compile("\\.([a-zA-Z0-9]{2,5})$");

    private final FileStorageService storage;
    private volatile HttpClient httpClient;

    public GeneratedMediaLocalizer(FileStorageService storage) {
        this.storage = storage;
    }

    public AiTaskResult localize(AiTaskResult result,
                                 TaskType taskType,
                                 String taskNo) {
        if (result == null || !result.success()) {
            return result;
        }

        String localResultUrl = localizeOne(
                result.resultUrl(), taskNo + "_result", taskType, false);
        String localThumbUrl = localizeOne(
                result.thumbnailUrl(), taskNo + "_thumb", taskType, true);

        return new AiTaskResult(
                result.success(),
                result.providerTaskId(),
                localResultUrl,
                localThumbUrl,
                result.resultJson(),
                result.errorMessage(),
                result.elapsedMs()
        );
    }

    private String localizeOne(String url,
                               String prefix,
                               TaskType taskType,
                               boolean thumbnail) {
        if (url == null || url.isBlank() || url.startsWith("/upload/")) {
            return url;
        }
        if (!(url.startsWith("http://") || url.startsWith("https://"))) {
            return url;
        }

        try {
            HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(90))
                    .header("User-Agent", "opc-server")
                    .GET()
                    .build();
            HttpResponse<byte[]> response = httpClient().send(
                    request, HttpResponse.BodyHandlers.ofByteArray());

            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new IllegalStateException("HTTP " + response.statusCode());
            }
            byte[] body = response.body();
            if (body == null || body.length == 0) {
                throw new IllegalStateException("响应内容为空");
            }
            if (body.length > MAX_MEDIA_BYTES) {
                throw new IllegalStateException("媒体文件超过 100MB");
            }

            String contentType = response.headers()
                    .firstValue("content-type")
                    .orElse("");
            String extension = extensionFromContentType(contentType);
            if (extension == null) {
                extension = extensionFromUrl(url);
            }
            if (extension == null) {
                extension = thumbnail
                        ? "png"
                        : switch (taskType) {
                            case TEXT_TO_IMAGE -> "png";
                            case IMAGE_TO_VIDEO -> "mp4";
                            case TEXT_TO_AUDIO -> "mp3";
                        };
            }

            String storedUrl = storage.saveBytes(body, extension, prefix);
            log.info("已转存第三方生成结果 {} -> {}，{} bytes",
                    url, storedUrl, body.length);
            return storedUrl;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            if (thumbnail) {
                log.warn("缩略图转存被中断，忽略缩略图: {}", url);
                return null;
            }
            throw new IllegalStateException("结果文件转存被中断", e);
        } catch (Exception e) {
            if (thumbnail) {
                log.warn("缩略图转存失败，忽略缩略图: {}，原因：{}", url, e.getMessage());
                return null;
            }
            log.error("生成结果转存失败: {}", url, e);
            throw new IllegalStateException("生成成功，但结果文件转存失败：" + e.getMessage(), e);
        }
    }

    private HttpClient httpClient() {
        HttpClient client = httpClient;
        if (client == null) {
            synchronized (this) {
                client = httpClient;
                if (client == null) {
                    client = HttpClient.newBuilder()
                            .connectTimeout(Duration.ofSeconds(15))
                            .followRedirects(HttpClient.Redirect.NORMAL)
                            .build();
                    httpClient = client;
                }
            }
        }
        return client;
    }

    private String extensionFromContentType(String contentType) {
        String type = contentType.toLowerCase(Locale.ROOT).split(";", 2)[0].trim();
        return switch (type) {
            case "image/png" -> "png";
            case "image/jpeg", "image/jpg" -> "jpg";
            case "image/webp" -> "webp";
            case "image/gif" -> "gif";
            case "video/mp4" -> "mp4";
            case "video/webm" -> "webm";
            case "video/quicktime" -> "mov";
            case "audio/mpeg", "audio/mp3" -> "mp3";
            case "audio/wav", "audio/x-wav" -> "wav";
            default -> null;
        };
    }

    private String extensionFromUrl(String url) {
        try {
            String path = URI.create(url).getPath();
            if (path == null) {
                return null;
            }
            String filename = path.substring(path.lastIndexOf('/') + 1);
            var matcher = EXTENSION_PATTERN.matcher(filename);
            return matcher.find()
                    ? matcher.group(1).toLowerCase(Locale.ROOT)
                    : null;
        } catch (Exception ignored) {
            return null;
        }
    }
}
