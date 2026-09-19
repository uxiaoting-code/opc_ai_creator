package com.opc.server.ai.impl;

// 注意：Spring Boot 4 用的是 Jackson 3，包名从 com.fasterxml.jackson.databind
// 变成了 tools.jackson.databind（注解仍在 com.fasterxml.jackson.annotation，没变）。
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.opc.server.ai.AiProvider;
import com.opc.server.ai.AiTaskRequest;
import com.opc.server.ai.AiTaskResult;
import com.opc.server.ai.ProgressListener;
import com.opc.server.ai.ProviderNames;
import com.opc.server.storage.FileStorageService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

import javax.imageio.ImageIO;

/**
 * 真实 AI 绘图服务商接入模板 —— <b>「填入密钥即可对接」的落点。</b>
 *
 * <p>以最常见的 Stable Diffusion WebUI API（{@code /sdapi/v1/txt2img}）为范例，
 * 走完了真实服务商的完整流程：构造请求体 → 带密钥调用 → 解析 base64 结果 →
 * 落盘 → 返回可访问 URL。
 *
 * <h3>怎么启用</h3>
 * <p>本类默认<b>不注册</b>（{@code @ConditionalOnProperty} 控制），
 * 所以不配密钥时不会干扰 Mock 链路。要用的时候改配置即可：
 * <pre>
 * opc:
 *   provider:
 *     stable-diffusion:
 *       enabled: true
 *       base-url: http://127.0.0.1:7860
 *       api-key: sk-xxxxxxxx        # 填入真实密钥
 * </pre>
 * 然后把 {@code t_skill} 里某条线路的 {@code provider} 改成
 * {@code stable-diffusion}，那条线路就会走真实模型，其它线路不受影响。
 *
 * <h3>换成别家服务商</h3>
 * <p>复制这个类，改三处：
 * <ol>
 *   <li>{@link #getName()} 返回新的标识（同时在 {@link ProviderNames} 里加个常量）；</li>
 *   <li>{@link #buildRequestBody} 按对方的参数规范拼 body；</li>
 *   <li>{@link #parseImageBytes} 按对方的响应结构取图。</li>
 * </ol>
 * Harness 调度代码、Controller、前端<b>一行都不用改</b> —— 这就是
 * {@link AiProvider} 抽象的价值。
 */
@Component
@ConditionalOnProperty(
        prefix = "opc.provider.stable-diffusion",
        name = "enabled",
        havingValue = "true")
public class StableDiffusionProvider implements AiProvider {

    private static final Logger log = LoggerFactory.getLogger(StableDiffusionProvider.class);

    private final FileStorageService storage;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    @Value("${opc.provider.stable-diffusion.base-url:http://127.0.0.1:7860}")
    private String baseUrl;

    @Value("${opc.provider.stable-diffusion.api-key:}")
    private String apiKey;

    @Value("${opc.provider.stable-diffusion.timeout-seconds:180}")
    private long timeoutSeconds;

    public StableDiffusionProvider(FileStorageService storage, ObjectMapper objectMapper) {
        this.storage = storage;
        this.objectMapper = objectMapper;
        // 用 JDK 自带的 HttpClient，不额外引依赖
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(15))
                .build();
    }

    @Override
    public String getName() {
        return ProviderNames.STABLE_DIFFUSION;
    }

    /**
     * 密钥/地址配好才算可用。
     *
     * <p>Harness 路由时若发现不可用会降级到 Mock 并打警告，
     * 而不是让任务直接失败 —— 课设演示不会因为少配一个密钥就卡住。
     */
    @Override
    public boolean isAvailable() {
        return baseUrl != null && !baseUrl.isBlank();
    }

    @Override
    public AiTaskResult submit(AiTaskRequest request, ProgressListener listener) {
        long start = System.currentTimeMillis();

        if (!isAvailable()) {
            return AiTaskResult.fail("服务商未配置：opc.provider.stable-diffusion.base-url 为空");
        }

        try {
            // SD WebUI 是同步接口，只能先给个「已提交」的进度
            listener.onProgress(10);

            String body = objectMapper.writeValueAsString(buildRequestBody(request));
            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/sdapi/v1/txt2img"))
                    .header("Content-Type", "application/json")
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .POST(HttpRequest.BodyPublishers.ofString(body));

            if (apiKey != null && !apiKey.isBlank()) {
                builder.header("Authorization", "Bearer " + apiKey);
            }

            listener.onProgress(30);

            HttpResponse<String> response = httpClient.send(
                    builder.build(), HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                log.warn("SD 接口返回非 200: {} body={}", response.statusCode(), response.body());
                return AiTaskResult.fail("服务商返回错误（HTTP %d）".formatted(response.statusCode()),
                        System.currentTimeMillis() - start);
            }

            listener.onProgress(70);

            byte[] imageBytes = parseImageBytes(response.body());
            if (imageBytes == null || imageBytes.length == 0) {
                return AiTaskResult.fail("服务商未返回图片数据",
                        System.currentTimeMillis() - start);
            }

            String url = storage.saveBytes(imageBytes, "png", "task_" + request.taskNo());
            listener.onProgress(100);

            long elapsed = System.currentTimeMillis() - start;
            log.info("SD 生成完成 taskNo={} 耗时={}ms url={}",
                    request.taskNo(), elapsed, url);

            return AiTaskResult.ok(url, url, elapsed);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return AiTaskResult.fail("任务被中断");
        } catch (Exception e) {
            // 网络超时、限流、鉴权失败都走这里，转成业务失败交给 Harness 重试
            log.error("调用 SD 服务商失败 taskNo={}", request.taskNo(), e);
            return AiTaskResult.fail("调用服务商失败：" + e.getMessage(),
                    System.currentTimeMillis() - start);
        }
    }

    /**
     * 按 Stable Diffusion WebUI 的参数规范拼请求体。
     *
     * <p>换服务商时改这个方法 —— 这就是「参数解耦」的具体体现：
     * 上层永远只给 {@link AiTaskRequest}，翻译工作由 Provider 自己做。
     */
    private Map<String, Object> buildRequestBody(AiTaskRequest request) {
        Map<String, Object> body = new HashMap<>();

        body.put("prompt", request.prompt() == null ? "" : request.prompt());
        body.put("negative_prompt",
                request.negativePrompt() == null ? "" : request.negativePrompt());
        body.put("width", request.safeWidth());
        body.put("height", request.safeHeight());
        body.put("steps", request.steps() == null ? 25 : request.steps());
        body.put("cfg_scale", request.cfgScale() == null ? 7.0 : request.cfgScale());
        body.put("batch_size", 1);
        body.put("n_iter", 1);

        if (request.seed() != null) {
            body.put("seed", request.seed());
        }

        // 图生视频线路如果传的是首帧图，SD 的 img2img 流程会用到；
        // 这里先透传，具体由服务商侧决定怎么用
        if (request.referenceImageUrl() != null && !request.referenceImageUrl().isBlank()) {
            body.put("init_images", java.util.List.of(request.referenceImageUrl()));
        }

        // 线路的扩展参数直接透传，新增参数不用改代码
        if (request.extraParams() != null) {
            body.putAll(request.extraParams());
        }

        return body;
    }

    /** 从响应里取图片字节。SD WebUI 返回的是 base64 数组。 */
    private byte[] parseImageBytes(String responseBody) throws Exception {
        JsonNode root = objectMapper.readTree(responseBody);
        JsonNode images = root.get("images");
        if (images == null || !images.isArray() || images.isEmpty()) {
            return null;
        }
        String base64 = images.get(0).asText();
        // 有些版本会带 data:image/png;base64, 前缀，去掉再解
        int comma = base64.indexOf(',');
        if (base64.startsWith("data:") && comma > 0) {
            base64 = base64.substring(comma + 1);
        }
        byte[] bytes = Base64.getDecoder().decode(base64);

        // 校验一下确实是图片，避免把错误信息当图片存下来
        try (ByteArrayInputStream in = new ByteArrayInputStream(bytes)) {
            BufferedImage image = ImageIO.read(in);
            return image == null ? null : bytes;
        }
    }
}
