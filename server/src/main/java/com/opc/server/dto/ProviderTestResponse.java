package com.opc.server.dto;

import com.opc.server.ai.ProviderTestResult;

/** 需求 3.1 第 5 步：连通性测试结果。 */
public record ProviderTestResponse(
        boolean success,
        int httpStatus,
        long elapsedMs,
        String extractedResultUrl,
        String extractedError,
        String rawResponse,
        boolean rawResponseTruncated,
        String message
) {

    public static ProviderTestResponse from(ProviderTestResult r) {
        return new ProviderTestResponse(
                r.success(), r.httpStatus(), r.elapsedMs(),
                r.extractedResultUrl(), r.extractedError(),
                r.rawResponse(), r.rawResponseTruncated(), r.message()
        );
    }

    public static ProviderTestResponse of(boolean success, String message) {
        return new ProviderTestResponse(success, 0, 0L, null, null, null, false, message);
    }
}
