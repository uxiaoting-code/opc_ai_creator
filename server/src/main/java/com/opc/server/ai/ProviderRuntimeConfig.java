package com.opc.server.ai;

/**
 * 配置化 HTTP 服务商的运行时配置。
 *
 * <p>刻意不直接引用 {@code AiProviderConfig} 实体：AI 层保持对持久化的无知，
 * 由 Service 层负责「实体 → 本 record」的映射。
 */
public record ProviderRuntimeConfig(
        String providerImpl,
        String name,
        String modelName,
        String type,
        String baseUrl,
        String authType,
        String apiKey,
        String headerName,
        String headerValue,
        String requestMethod,
        String requestPath,
        String requestContentType,
        String requestQueryJson,
        String requestHeadersJson,
        String requestBodyJson,
        String responseSuccessPath,
        String responseResultUrlPath,
        String responseThumbPath,
        String responseErrorPath,
        String responseTaskIdPath,
        int timeoutSeconds
) {
}
