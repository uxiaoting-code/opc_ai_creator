package com.opc.server.ai.impl;

import com.opc.server.ai.AiTaskRequest;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Shared helpers for template-driven Volcengine providers.
 *
 * <p>The concrete API paths and field names are intentionally supplied by
 * configuration until the official Volcengine contract is frozen. This lets
 * the same provider code handle the documented request/response shape without
 * embedding guessed vendor endpoints in Java.
 */
abstract class VolcengineProviderSupport {

    protected final ObjectMapper objectMapper;
    protected final HttpClient httpClient;

    protected VolcengineProviderSupport(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(15))
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();
    }

    protected HttpResponse<String> send(HttpRequest request)
            throws Exception {
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
    }

    protected HttpResponse<byte[]> sendBytes(HttpRequest request)
            throws Exception {
        return httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
    }

    protected HttpRequest buildRequest(String method,
                                       String url,
                                       String apiKey,
                                       String authHeaderName,
                                       String authHeaderPrefix,
                                       String contentType,
                                       String headersJson,
                                       String body,
                                       int timeoutSeconds) {
        String safeMethod = method == null || method.isBlank() ? "POST" : method.trim().toUpperCase();
        HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(Math.max(5, timeoutSeconds)));

        if ("GET".equals(safeMethod)) {
            builder.GET();
        } else {
            builder.method(safeMethod, HttpRequest.BodyPublishers.ofString(
                    body == null ? "" : body, StandardCharsets.UTF_8));
        }

        builder.header("Content-Type",
                contentType == null || contentType.isBlank() ? "application/json" : contentType);
        addHeaders(builder, headersJson);

        if (apiKey != null && !apiKey.isBlank()
                && authHeaderName != null && !authHeaderName.isBlank()) {
            String value = authHeaderPrefix == null ? apiKey : authHeaderPrefix + apiKey;
            builder.header(authHeaderName, value);
        }
        return builder.build();
    }

    protected String buildUrl(String baseUrl, String path, Map<String, String> vars) {
        String base = baseUrl == null ? "" : baseUrl.trim();
        String renderedPath = render(path, vars).trim();
        if (renderedPath.isBlank()) {
            return "";
        }
        if (renderedPath.startsWith("http://") || renderedPath.startsWith("https://")) {
            return renderedPath;
        }
        if (base.isBlank()) {
            return renderedPath;
        }
        if (base.endsWith("/") && renderedPath.startsWith("/")) {
            return base + renderedPath.substring(1);
        }
        if (!base.endsWith("/") && !renderedPath.startsWith("/")) {
            return base + "/" + renderedPath;
        }
        return base + renderedPath;
    }

    protected Map<String, String> baseVars(AiTaskRequest request,
                                           String model,
                                           String region,
                                           String apiKey) {
        Map<String, String> vars = new LinkedHashMap<>();
        vars.put("taskNo", safe(request.taskNo()));
        vars.put("taskType", request.taskType() == null ? "" : request.taskType().name());
        vars.put("prompt", safe(request.prompt()));
        vars.put("negativePrompt", safe(request.negativePrompt()));
        vars.put("refImageUrl", safe(request.referenceImageUrl()));
        vars.put("model", safe(model == null || model.isBlank() ? request.modelName() : model));
        vars.put("modelName", safe(request.modelName()));
        vars.put("region", safe(region));
        vars.put("apiKey", safe(apiKey));
        vars.put("width", String.valueOf(request.safeWidth()));
        vars.put("height", String.valueOf(request.safeHeight()));
        vars.put("steps", String.valueOf(request.steps() == null ? 25 : request.steps()));
        vars.put("cfgScale", String.valueOf(request.cfgScale() == null ? 7.0 : request.cfgScale()));
        vars.put("seed", request.seed() == null ? "" : String.valueOf(request.seed()));
        if (request.extraParams() != null) {
            request.extraParams().forEach((key, value) ->
                    vars.put(key, value == null ? "" : String.valueOf(value)));
        }
        return vars;
    }

    protected String render(String template, Map<String, String> vars) {
        if (template == null || template.isBlank()) {
            return "";
        }
        String result = template;
        for (Map.Entry<String, String> entry : vars.entrySet()) {
            result = result.replace("{{" + entry.getKey() + "}}", safe(entry.getValue()));
        }
        return result;
    }

    protected JsonNode parseSafely(String body) {
        if (body == null || body.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readTree(body);
        } catch (Exception e) {
            return null;
        }
    }

    protected String extract(JsonNode root, String path) {
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

    protected Integer extractInt(JsonNode root, String path) {
        String value = extract(root, path);
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    protected boolean matches(String value, String csv) {
        if (value == null || csv == null || csv.isBlank()) {
            return false;
        }
        String normalized = value.trim().toLowerCase();
        return Arrays.stream(csv.split(","))
                .map(String::trim)
                .filter(item -> !item.isEmpty())
                .anyMatch(item -> item.equalsIgnoreCase(normalized));
    }

    protected String errorMessage(JsonNode root, String errorPath, int statusCode) {
        String extracted = extract(root, errorPath);
        return extracted == null || extracted.isBlank() ? "HTTP " + statusCode : extracted;
    }

    protected String safe(String value) {
        return value == null ? "" : value;
    }

    private void addHeaders(HttpRequest.Builder builder, String headersJson) {
        if (headersJson == null || headersJson.isBlank()) {
            return;
        }
        try {
            JsonNode root = objectMapper.readTree(headersJson);
            if (root != null && root.isObject()) {
                root.properties().forEach(entry -> {
                    try {
                        builder.header(entry.getKey(), entry.getValue().asText());
                    } catch (Exception ignored) {
                        // Ignore invalid optional headers, not the provider call itself.
                    }
                });
            }
        } catch (Exception ignored) {
            // Configuration errors are surfaced by the request result when required.
        }
    }
}