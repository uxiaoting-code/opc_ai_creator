package com.opc.server.ai.impl;

import com.opc.server.ai.AiTaskRequest;
import com.opc.server.ai.AiTaskResult;
import com.opc.server.ai.ConfigAwareAiProvider;
import com.opc.server.ai.ProgressListener;
import com.opc.server.ai.ProviderNames;
import com.opc.server.ai.ProviderRuntimeConfig;
import com.opc.server.ai.ProviderTestResult;
import com.opc.server.entity.enums.TaskType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 配置驱动的通用 HTTP 服务商。
 *
 * <p>需求 3.1 的第 3、4、5 步由它落地：
 * 请求模板（方法/路径/查询/请求头/Body）→ 发 HTTP → 响应模板（字段提取）→ 返回统一结果。
 *
 * <p>模板变量冻结在 {@code docs/api-admin.md} §④：
 * {@code {{prompt}} {{negativePrompt}} {{modelName}} {{width}} {{height}}
 * {{steps}} {{cfgScale}} {{seed}} {{refImageUrl}} {{taskNo}} {{apiKey}}}
 */
@Component
public class HttpApiProvider implements ConfigAwareAiProvider {

    private static final Logger log = LoggerFactory.getLogger(HttpApiProvider.class);
    private static final int RAW_RESPONSE_LIMIT = 2000;

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public HttpApiProvider(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();
    }

    @Override
    public String getName() {
        return ProviderNames.HTTP;
    }

    @Override
    public boolean isAvailable() {
        return true;
    }

    /**
     * 接口要求实现，但配置化 HTTP 必须拿到 {@link ProviderRuntimeConfig} 才能工作。
     * 走 {@code t_skill.provider = "http"} 的旧链路会收到明确的失败提示，而不是空指针。
     */
    @Override
    public AiTaskResult submit(AiTaskRequest request, ProgressListener listener) {
        return AiTaskResult.fail("http 服务商必须通过配置调用（缺少 AiProviderConfig）");
    }

    @Override
    public AiTaskResult submit(ProviderRuntimeConfig config,
                               AiTaskRequest request,
                               ProgressListener listener) {
        long start = System.currentTimeMillis();
        try {
            listener.onProgress(10);
            Map<String, String> vars = buildVars(config, request);
            HttpRequest httpRequest = buildRequest(config, request, vars);

            listener.onProgress(30);
            HttpResponse<String> response = httpClient.send(
                    httpRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            long elapsed = System.currentTimeMillis() - start;

            JsonNode root = parseSafely(response.body());
            if (!isSuccess(config, response.statusCode(), root)) {
                String error = extract(root, config.responseErrorPath());
                if (error == null || error.isBlank()) {
                    error = "HTTP " + response.statusCode();
                }
                return AiTaskResult.fail(error, elapsed);
            }

            String resultUrl = extract(root, config.responseResultUrlPath());
            if (resultUrl == null || resultUrl.isBlank()) {
                return AiTaskResult.fail("响应模板未提取到结果地址", elapsed);
            }
            String thumb = extract(root, config.responseThumbPath());
            listener.onProgress(100);
            return AiTaskResult.ok(resultUrl, thumb, response.body(), elapsed);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return AiTaskResult.fail("请求被中断", System.currentTimeMillis() - start);
        } catch (Exception e) {
            log.warn("HTTP 服务商调用失败：{}", e.getMessage());
            return AiTaskResult.fail("HTTP 调用失败：" + e.getMessage(),
                    System.currentTimeMillis() - start);
        }
    }

    @Override
    public ProviderTestResult test(ProviderRuntimeConfig config, String prompt) {
        long start = System.currentTimeMillis();
        try {
            AiTaskRequest request = buildTestRequest(config, prompt);
            Map<String, String> vars = buildVars(config, request);
            HttpRequest httpRequest = buildRequest(config, request, vars);

            HttpResponse<String> response = httpClient.send(
                    httpRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            long elapsed = System.currentTimeMillis() - start;

            String raw = response.body();
            boolean truncated = raw != null && raw.length() > RAW_RESPONSE_LIMIT;
            String shown = truncated ? raw.substring(0, RAW_RESPONSE_LIMIT) : raw;

            JsonNode root = parseSafely(raw);
            String error = extract(root, config.responseErrorPath());
            String resultUrl = extract(root, config.responseResultUrlPath());
            boolean success = isSuccess(config, response.statusCode(), root);
            if (!success && (error == null || error.isBlank())) {
                error = "HTTP " + response.statusCode();
            }
            String message = success
                    ? "连通性正常，已按响应模板提取到字段"
                    : "连通性失败：" + safe(error);

            return new ProviderTestResult(success, response.statusCode(), elapsed,
                    resultUrl, error, shown, truncated, message);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return new ProviderTestResult(false, 0,
                    System.currentTimeMillis() - start, null, "请求被中断",
                    null, false, "请求被中断");
        } catch (Exception e) {
            log.warn("连通性测试失败：{}", e.getMessage());
            return new ProviderTestResult(false, 0,
                    System.currentTimeMillis() - start, null, e.getMessage(),
                    null, false, "请求失败：" + e.getMessage());
        }
    }

    // =========================================================================
    // 请求构造
    // =========================================================================

    private AiTaskRequest buildTestRequest(ProviderRuntimeConfig config, String prompt) {
        return new AiTaskRequest(
                "test-" + System.currentTimeMillis(),
                TaskType.TEXT_TO_IMAGE,
                defaultIfBlank(prompt, "连通性测试：一只在窗边晒太阳的猫"),
                null, null, null,
                config.modelName(),
                25, 7.0, 1024, 1024, null, 0, Map.of()
        );
    }

    private HttpRequest buildRequest(ProviderRuntimeConfig config,
                                     AiTaskRequest request,
                                     Map<String, String> vars) throws Exception {
        String url = buildUrl(config, request, vars);
        String method = defaultIfBlank(config.requestMethod(), "POST").trim().toUpperCase();

        String bodyTemplate = defaultIfBlank(config.requestBodyJson(),
                "{\"prompt\":\"{{prompt}}\",\"model\":\"{{modelName}}\"}");
        String body = render(bodyTemplate, vars);

        HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(Math.max(5, config.timeoutSeconds())));

        if ("GET".equals(method)) {
            builder.GET();
        } else {
            builder.method(method, HttpRequest.BodyPublishers.ofString(
                    body == null ? "" : body, StandardCharsets.UTF_8));
        }

        builder.header("Content-Type",
                defaultIfBlank(config.requestContentType(), "application/json"));
        applyAuth(builder, config, vars);
        applyCustomHeaders(builder, config, vars);
        return builder.build();
    }

    private String buildUrl(ProviderRuntimeConfig config,
                            AiTaskRequest request,
                            Map<String, String> vars) {
        String base = safe(config.baseUrl()).trim();
        String path = render(safe(config.requestPath()), vars).trim();

        String url;
        if (path.startsWith("http://") || path.startsWith("https://")) {
            url = path;
        } else if (base.isEmpty()) {
            url = path;
        } else if (base.endsWith("/") && path.startsWith("/")) {
            url = base + path.substring(1);
        } else if (!base.endsWith("/") && !path.startsWith("/")) {
            url = base + "/" + path;
        } else {
            url = base + path;
        }

        String query = buildQuery(config.requestQueryJson(), vars);
        if (!query.isBlank()) {
            url = url + (url.contains("?") ? "&" : "?") + query;
        }
        return url;
    }

    private String buildQuery(String queryJson, Map<String, String> vars) {
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Object> entry : readObject(queryJson).entrySet()) {
            String value = render(String.valueOf(entry.getValue() == null ? "" : entry.getValue()), vars);
            if (sb.length() > 0) {
                sb.append('&');
            }
            sb.append(URLEncoder.encode(entry.getKey(), StandardCharsets.UTF_8))
                    .append('=')
                    .append(URLEncoder.encode(value, StandardCharsets.UTF_8));
        }
        return sb.toString();
    }

    private void applyAuth(HttpRequest.Builder builder,
                           ProviderRuntimeConfig config,
                           Map<String, String> vars) {
        String authType = defaultIfBlank(config.authType(), "NONE").trim().toUpperCase();
        switch (authType) {
            case "API_KEY" -> {
                String key = render(safe(config.apiKey()), vars).trim();
                if (key.isEmpty()) {
                    return;
                }
                String header = defaultIfBlank(config.headerName(), "Authorization").trim();
                if ("Authorization".equalsIgnoreCase(header)) {
                    builder.header(header, "Bearer " + key);
                } else {
                    builder.header(header, key);
                }
            }
            case "CUSTOM_HEADER" -> {
                String header = safe(config.headerName()).trim();
                if (!header.isEmpty()) {
                    builder.header(header, render(safe(config.headerValue()), vars));
                }
            }
            case "OAUTH" -> {
                // 第一版不实现完整的 OAuth 授权码/客户端凭证流程；
                // 如果运营人员已把 access token 填在 apiKey 里，就当作 Bearer 使用。
                String token = render(safe(config.apiKey()), vars).trim();
                if (!token.isEmpty()) {
                    builder.header("Authorization", "Bearer " + token);
                }
            }
            default -> {
                // NONE：不加鉴权头
            }
        }
    }

    private void applyCustomHeaders(HttpRequest.Builder builder,
                                    ProviderRuntimeConfig config,
                                    Map<String, String> vars) {
        for (Map.Entry<String, Object> entry : readObject(config.requestHeadersJson()).entrySet()) {
            String name = render(entry.getKey(), vars).trim();
            if (name.isEmpty()) {
                continue;
            }
            String value = render(String.valueOf(entry.getValue() == null ? "" : entry.getValue()), vars);
            try {
                builder.header(name, value);
            } catch (IllegalArgumentException e) {
                log.warn("忽略非法的请求头 {}：{}", name, e.getMessage());
            }
        }
    }

    // =========================================================================
    // 响应解析
    // =========================================================================

    private boolean isSuccess(ProviderRuntimeConfig config, int status, JsonNode root) {
        if (status < 200 || status >= 300) {
            return false;
        }
        String successPath = config.responseSuccessPath();
        if (successPath == null || successPath.isBlank()) {
            return true;
        }
        return truthy(extract(root, successPath));
    }

    /**
     * 按点号路径取值，数字段表示数组下标。
     * 例：{@code data.0.url}、{@code output.images.0}。
     */
    private String extract(JsonNode root, String path) {
        if (root == null || path == null || path.isBlank()) {
            return null;
        }
        JsonNode node = root;
        for (String part : path.trim().split("\\.")) {
            if (node == null || node.isMissingNode() || node.isNull()) {
                return null;
            }
            if (node.isArray()) {
                try {
                    node = node.get(Integer.parseInt(part));
                } catch (NumberFormatException e) {
                    return null;
                }
            } else {
                node = node.get(part);
            }
        }
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        return node.isValueNode() ? node.asText() : node.toString();
    }

    private JsonNode parseSafely(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readTree(raw);
        } catch (Exception e) {
            return null;
        }
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> readObject(String json) {
        if (json == null || json.isBlank()) {
            return Map.of();
        }
        try {
            JsonNode node = objectMapper.readTree(json);
            if (node == null || !node.isObject()) {
                return Map.of();
            }
            Map<String, Object> map = objectMapper.convertValue(node, Map.class);
            return map == null ? Map.of() : map;
        } catch (Exception e) {
            log.warn("模板 JSON 解析失败：{}", e.getMessage());
            return Map.of();
        }
    }

    // =========================================================================
    // 工具方法
    // =========================================================================

    private Map<String, String> buildVars(ProviderRuntimeConfig config, AiTaskRequest request) {
        Map<String, String> vars = new LinkedHashMap<>();
        vars.put("prompt", safe(request.prompt()));
        vars.put("negativePrompt", safe(request.negativePrompt()));
        vars.put("modelName", defaultIfBlank(request.modelName(), safe(config.modelName())));
        vars.put("width", String.valueOf(request.safeWidth()));
        vars.put("height", String.valueOf(request.safeHeight()));
        vars.put("steps", String.valueOf(request.steps() == null ? 25 : request.steps()));
        vars.put("cfgScale", String.valueOf(request.cfgScale() == null ? 7.0 : request.cfgScale()));
        vars.put("seed", request.seed() == null ? "" : String.valueOf(request.seed()));
        vars.put("refImageUrl", safe(request.referenceImageUrl()));
        vars.put("taskNo", safe(request.taskNo()));
        vars.put("apiKey", safe(config.apiKey()));
        if (request.extraParams() != null) {
            request.extraParams().forEach((key, value) ->
                    vars.put(key, value == null ? "" : String.valueOf(value)));
        }
        return vars;
    }

    private String render(String template, Map<String, String> vars) {
        if (template == null || template.isEmpty()) {
            return "";
        }
        String result = template;
        for (Map.Entry<String, String> entry : vars.entrySet()) {
            result = result.replace("{{" + entry.getKey() + "}}",
                    entry.getValue() == null ? "" : entry.getValue());
        }
        return result;
    }

    private boolean truthy(String value) {
        if (value == null) {
            return false;
        }
        String v = value.trim();
        return !(v.isEmpty()
                || "false".equalsIgnoreCase(v)
                || "0".equals(v)
                || "null".equalsIgnoreCase(v));
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }

    private static String defaultIfBlank(String value, String fallback) {
        return (value == null || value.isBlank()) ? fallback : value;
    }
}
