package com.opc.server.dto;

/** 需求 3.1 第 3 步：请求模板。 */
public record ProviderRequestTemplateRequest(
        String method,
        String path,
        String contentType,
        String queryJson,
        String headersJson,
        String bodyJson
) {
}
