package com.opc.server.ai.impl;

import com.opc.server.ai.AiProvider;
import com.opc.server.ai.AiTaskRequest;
import com.opc.server.ai.AiTaskResult;
import com.opc.server.ai.ProgressListener;
import com.opc.server.ai.ProviderNames;
import com.opc.server.config.VolcengineTtsProperties;
import com.opc.server.storage.FileStorageService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

/** Volcengine TTS provider. */
@Component
@ConditionalOnProperty(
        prefix = "opc.provider.volcengine-tts",
        name = "enabled",
        havingValue = "true")
public class VolcengineTtsProvider extends VolcengineProviderSupport implements AiProvider {

    private static final Logger log = LoggerFactory.getLogger(VolcengineTtsProvider.class);

    private final VolcengineTtsProperties properties;
    private final FileStorageService storage;

    public VolcengineTtsProvider(VolcengineTtsProperties properties,
                                 FileStorageService storage,
                                 ObjectMapper objectMapper) {
        super(objectMapper);
        this.properties = properties;
        this.storage = storage;
    }

    @Override
    public String getName() {
        return ProviderNames.VOLCENGINE_TTS;
    }

    @Override
    public boolean isAvailable() {
        return properties.isEnabled()
                && !isBlank(properties.getBaseUrl())
                && !isBlank(properties.getApiKey())
                && !isBlank(properties.getModel())
                && !isBlank(properties.getCreatePath());
    }

    @Override
    public AiTaskResult submit(AiTaskRequest request, ProgressListener listener) {
        long start = System.currentTimeMillis();
        if (!isAvailable()) {
            return AiTaskResult.fail("Volcengine TTS provider is not fully configured");
        }
        try {
            listener.onProgress(10);
            Map<String, String> vars = baseVars(
                    request, properties.getModel(), properties.getRegion(), properties.getApiKey());
            fillTtsDefaults(vars, request);
            String body = render(properties.getRequestBodyJson(), vars);
            if (body.isBlank()) {
                return AiTaskResult.fail("Volcengine TTS requestBodyJson is empty", elapsed(start));
            }

            String url = buildUrl(properties.getBaseUrl(), properties.getCreatePath(), vars);
            HttpRequest httpRequest = buildRequest(
                    properties.getRequestMethod(), url, properties.getApiKey(),
                    properties.getAuthHeaderName(), properties.getAuthHeaderPrefix(),
                    properties.getRequestContentType(), properties.getHeadersJson(),
                    body, properties.getTimeoutSeconds());
            HttpResponse<byte[]> response = sendBytes(httpRequest);
            String raw = new String(response.body(), StandardCharsets.UTF_8);
            JsonNode root = parseSafely(raw);
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                return AiTaskResult.fail(
                        errorMessage(root, properties.getResponseErrorPath(), response.statusCode()),
                        elapsed(start));
            }
            if (isBinaryAudio(response, root)) {
                String saved = saveAudioBytes(response.body(), vars.get("format"), request.taskNo());
                listener.onProgress(100);
                return AiTaskResult.ok(saved, null, "{\"contentType\":\"" + response.headers().firstValue("Content-Type").orElse("") + "\"}", elapsed(start));
            }

            String audioUrl = extract(root, properties.getResponseAudioUrlPath());
            if (!isBlank(audioUrl)) {
                listener.onProgress(100);
                return AiTaskResult.ok(audioUrl, null, raw, elapsed(start));
            }

            String base64 = extract(root, properties.getResponseAudioBase64Path());
            if (!isBlank(base64)) {
                String saved = saveAudio(base64, vars.get("format"), request.taskNo());
                listener.onProgress(100);
                return AiTaskResult.ok(saved, null, raw, elapsed(start));
            }

            String taskId = extract(root, properties.getResponseTaskIdPath());
            if (!isBlank(taskId)) {
                return AiTaskResult.async(taskId, 10, raw, elapsed(start));
            }

            return AiTaskResult.fail("Volcengine TTS response has no audio result or task id", elapsed(start));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return AiTaskResult.fail("Volcengine TTS request interrupted", elapsed(start));
        } catch (Exception e) {
            log.warn("Volcengine TTS submit failed taskNo={}: {}", request.taskNo(), e.getMessage());
            return AiTaskResult.fail("Volcengine TTS call failed: " + e.getMessage(), elapsed(start));
        }
    }
    @Override
    public AiTaskResult query(String providerTaskId) {
        long start = System.currentTimeMillis();
        if (isBlank(providerTaskId)) {
            return AiTaskResult.fail("Volcengine TTS providerTaskId is empty");
        }
        if (!isAvailable() || isBlank(properties.getQueryPath())) {
            return AiTaskResult.fail("Volcengine TTS query is not configured");
        }
        try {
            Map<String, String> vars = queryVars(providerTaskId);
            String url = buildUrl(properties.getBaseUrl(), properties.getQueryPath(), vars);
            String body = render(properties.getQueryBodyJson(), vars);
            HttpRequest httpRequest = buildRequest(
                    properties.getQueryMethod(), url, properties.getApiKey(),
                    properties.getAuthHeaderName(), properties.getAuthHeaderPrefix(),
                    properties.getRequestContentType(), properties.getHeadersJson(),
                    body, properties.getTimeoutSeconds());
            HttpResponse<byte[]> response = sendBytes(httpRequest);
            String raw = new String(response.body(), StandardCharsets.UTF_8);
            JsonNode root = parseSafely(raw);
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                return AiTaskResult.fail(
                        errorMessage(root, properties.getResponseErrorPath(), response.statusCode()),
                        elapsed(start));
            }
            if (isBinaryAudio(response, root)) {
                String saved = saveAudioBytes(response.body(), "wav", "task_" + providerTaskId);
                return AiTaskResult.ok(providerTaskId, saved, null, "{\"contentType\":\"audio\"}", elapsed(start));
            }

            String status = extract(root, properties.getResponseStatusPath());
            String audioUrl = extract(root, properties.getResponseAudioUrlPath());
            String base64 = extract(root, properties.getResponseAudioBase64Path());
            Integer progress = extractInt(root, properties.getResponseProgressPath());

            if (matches(status, properties.getFailureStatuses())) {
                return AiTaskResult.fail(
                        errorMessage(root, properties.getResponseErrorPath(), response.statusCode()),
                        elapsed(start));
            }
            if (!isBlank(audioUrl)) {
                return AiTaskResult.ok(providerTaskId, audioUrl, null, raw, elapsed(start));
            }
            if (!isBlank(base64)) {
                String saved = saveAudio(base64, "wav", "task_" + providerTaskId);
                return AiTaskResult.ok(providerTaskId, saved, null, raw, elapsed(start));
            }
            if (matches(status, properties.getSuccessStatuses())) {
                return AiTaskResult.fail("Volcengine TTS succeeded without audio result", elapsed(start));
            }

            int currentProgress = progress == null ? 50 : Math.max(0, Math.min(99, progress));
            return AiTaskResult.async(providerTaskId, currentProgress, raw, elapsed(start));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return AiTaskResult.fail("Volcengine TTS query interrupted", elapsed(start));
        } catch (Exception e) {
            log.warn("Volcengine TTS query failed providerTaskId={}: {}", providerTaskId, e.getMessage());
            return AiTaskResult.fail("Volcengine TTS query failed: " + e.getMessage(), elapsed(start));
        }
    }

    @Override
    public boolean cancel(String providerTaskId) {
        if (isBlank(providerTaskId) || isBlank(properties.getCancelPath())) {
            return false;
        }
        try {
            Map<String, String> vars = queryVars(providerTaskId);
            String url = buildUrl(properties.getBaseUrl(), properties.getCancelPath(), vars);
            HttpRequest request = buildRequest(
                    properties.getCancelMethod(), url, properties.getApiKey(),
                    properties.getAuthHeaderName(), properties.getAuthHeaderPrefix(),
                    properties.getRequestContentType(), properties.getHeadersJson(),
                    "", properties.getTimeoutSeconds());
            HttpResponse<String> response = send(request);
            return response.statusCode() >= 200 && response.statusCode() < 300;
        } catch (Exception e) {
            log.warn("Volcengine TTS cancel failed providerTaskId={}: {}", providerTaskId, e.getMessage());
            return false;
        }
    }

    private void fillTtsDefaults(Map<String, String> vars, AiTaskRequest request) {
        vars.putIfAbsent("voiceCode", properties.getDefaultVoiceCode());
        vars.putIfAbsent("language", properties.getDefaultLanguage());
        vars.putIfAbsent("format", properties.getDefaultFormat());
        if (request.extraParams() != null) {
            request.extraParams().forEach((key, value) ->
                    vars.put(key, value == null ? "" : String.valueOf(value)));
        }
    }

    private Map<String, String> queryVars(String providerTaskId) {
        Map<String, String> vars = new LinkedHashMap<>();
        vars.put("providerTaskId", providerTaskId);
        vars.put("model", safe(properties.getModel()));
        vars.put("region", safe(properties.getRegion()));
        vars.put("apiKey", safe(properties.getApiKey()));
        return vars;
    }

    private boolean isBinaryAudio(HttpResponse<byte[]> response, JsonNode root) {
        String contentType = response.headers().firstValue("Content-Type").orElse("").toLowerCase();
        if (contentType.contains("json")) {
            return false;
        }
        return contentType.startsWith("audio/")
                || contentType.contains("octet-stream")
                || (root == null && response.body().length > 0);
    }

    private String saveAudioBytes(byte[] bytes, String format, String taskNo) {
        String extension = format == null || format.isBlank() ? properties.getDefaultFormat() : format;
        extension = extension.replace(".", "").trim().toLowerCase();
        if (extension.isBlank()) {
            extension = "wav";
        }
        return storage.saveBytes(bytes, extension, "task_" + taskNo);
    }

    private String saveAudio(String base64, String format, String taskNo) {
        String raw = base64;
        int comma = raw.indexOf(',');
        if (raw.startsWith("data:") && comma > 0) {
            raw = raw.substring(comma + 1);
        }
        byte[] bytes = Base64.getDecoder().decode(raw);
        String extension = format == null || format.isBlank() ? properties.getDefaultFormat() : format;
        extension = extension.replace(".", "").trim().toLowerCase();
        if (extension.isBlank()) {
            extension = "wav";
        }
        return storage.saveBytes(bytes, extension, "task_" + taskNo);
    }

    private long elapsed(long start) {
        return System.currentTimeMillis() - start;
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}