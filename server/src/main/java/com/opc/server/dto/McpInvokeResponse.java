package com.opc.server.dto;

public record McpInvokeResponse(
        boolean success,
        long elapsedMs,
        String result,
        String errorMessage
) {
}
