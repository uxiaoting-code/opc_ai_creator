package com.opc.server.ai;

/** 连通性测试结果（AI 层）。 */
public record ProviderTestResult(
        boolean success,
        int httpStatus,
        long elapsedMs,
        String extractedResultUrl,
        String extractedError,
        String rawResponse,
        boolean rawResponseTruncated,
        String message
) {

    public static ProviderTestResult fail(String message) {
        return new ProviderTestResult(false, 0, 0L, null, message, null, false, message);
    }
}
