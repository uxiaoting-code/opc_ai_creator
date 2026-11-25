package com.opc.server.ai.impl;

import com.opc.server.ai.AiProvider;
import com.opc.server.ai.AiTaskRequest;
import com.opc.server.ai.AiTaskResult;
import com.opc.server.ai.ProgressListener;
import com.opc.server.ai.ProviderNames;
import com.opc.server.config.VolcengineVideoProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.LinkedHashMap;
import java.util.Map;

/** Volcengine Ark/Seedance image-to-video provider. */
@Component
@ConditionalOnProperty(
        prefix = "opc.provider.volcengine-video",
        name = "enabled",
        havingValue = "true")
public class VolcengineVideoProvider extends VolcengineProviderSupport implements AiProvider {

    private static final Logger log = LoggerFactory.getLogger(VolcengineVideoProvider.class);

    private final VolcengineVideoProperties properties;

    public VolcengineVideoProvider(VolcengineVideoProperties properties, ObjectMapper objectMapper) {
        super(objectMapper);
        this.properties = properties;
    }

    @Override
    public String getName() {
        return ProviderNames.VOLCENGINE_VIDEO;
    }

    @Override
    public boolean isAvailable() {
        return properties.isEnabled()
                && !isBlank(properties.getBaseUrl())
                && !isBlank(properties.getApiKey())
                && !isBlank(properties.getModel())
                && !isBlank(properties.getCreatePath())
                && !isBlank(properties.getResponseTaskIdPath());
    }

    @Override
    public AiTaskResult submit(AiTaskRequest request, ProgressListener listener) {
        long start = System.currentTimeMillis();
        if (!isAvailable()) {
            return AiTaskResult.fail("Volcengine video provider is not fully configured");
        }
        try {
            listener.onProgress(5);
            Map<String, String> vars = baseVars(
                    request, properties.getModel(), properties.getRegion(), properties.getApiKey());
            String body = render(properties.getRequestBodyJson(), vars);
            if (body.isBlank()) {
                return AiTaskResult.fail("Volcengine video requestBodyJson is empty", elapsed(start));
            }

            String url = buildUrl(properties.getBaseUrl(), properties.getCreatePath(), vars);
            HttpRequest httpRequest = buildRequest(
                    properties.getRequestMethod(), url, properties.getApiKey(),
                    properties.getAuthHeaderName(), properties.getAuthHeaderPrefix(),
                    properties.getRequestContentType(), properties.getHeadersJson(),
                    body, properties.getTimeoutSeconds());
            listener.onProgress(15);
            HttpResponse<String> response = send(httpRequest);
            JsonNode root = parseSafely(response.body());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                return AiTaskResult.fail(
                        errorMessage(root, properties.getResponseErrorPath(), response.statusCode()),
                        elapsed(start));
            }

            String taskId = extract(root, properties.getResponseTaskIdPath());
            String resultUrl = extract(root, properties.getResponseResultUrlPath());
            String thumbUrl = extract(root, properties.getResponseThumbPath());
            if (isBlank(taskId) && isBlank(resultUrl)) {
                return AiTaskResult.fail("Volcengine video response has neither task id nor result url", elapsed(start));
            }

            listener.onProgress(30);
            if (!isBlank(resultUrl)) {
                return AiTaskResult.ok(taskId, resultUrl, thumbUrl, response.body(), elapsed(start));
            }
            log.info("Volcengine video task submitted taskNo={} providerTaskId={}", request.taskNo(), taskId);
            return AiTaskResult.async(taskId, 10, response.body(), elapsed(start));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return AiTaskResult.fail("Volcengine video request interrupted", elapsed(start));
        } catch (Exception e) {
            log.warn("Volcengine video submit failed taskNo={}: {}", request.taskNo(), e.getMessage());
            return AiTaskResult.fail("Volcengine video call failed: " + e.getMessage(), elapsed(start));
        }
    }
    @Override
    public AiTaskResult query(String providerTaskId) {
        long start = System.currentTimeMillis();
        if (isBlank(providerTaskId)) {
            return AiTaskResult.fail("Volcengine video providerTaskId is empty");
        }
        if (!isAvailable() || isBlank(properties.getQueryPath())) {
            return AiTaskResult.fail("Volcengine video query is not configured");
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
            HttpResponse<String> response = send(httpRequest);
            JsonNode root = parseSafely(response.body());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                return AiTaskResult.fail(
                        errorMessage(root, properties.getResponseErrorPath(), response.statusCode()),
                        elapsed(start));
            }

            String status = extract(root, properties.getResponseStatusPath());
            String resultUrl = extract(root, properties.getResponseResultUrlPath());
            String thumbUrl = extract(root, properties.getResponseThumbPath());
            String raw = response.body();
            Integer progress = extractInt(root, properties.getResponseProgressPath());

            if (matches(status, properties.getFailureStatuses())) {
                return AiTaskResult.fail(
                        errorMessage(root, properties.getResponseErrorPath(), response.statusCode()),
                        elapsed(start));
            }
            if (!isBlank(resultUrl) || matches(status, properties.getSuccessStatuses())) {
                if (isBlank(resultUrl)) {
                    return AiTaskResult.fail("Volcengine video succeeded without result url", elapsed(start));
                }
                return AiTaskResult.ok(providerTaskId, resultUrl, thumbUrl, raw, elapsed(start));
            }

            int currentProgress = progress == null ? 50 : Math.max(0, Math.min(99, progress));
            return AiTaskResult.async(providerTaskId, currentProgress, raw, elapsed(start));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return AiTaskResult.fail("Volcengine video query interrupted", elapsed(start));
        } catch (Exception e) {
            log.warn("Volcengine video query failed providerTaskId={}: {}", providerTaskId, e.getMessage());
            return AiTaskResult.fail("Volcengine video query failed: " + e.getMessage(), elapsed(start));
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
            log.warn("Volcengine video cancel failed providerTaskId={}: {}", providerTaskId, e.getMessage());
            return false;
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

    private long elapsed(long start) {
        return System.currentTimeMillis() - start;
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}