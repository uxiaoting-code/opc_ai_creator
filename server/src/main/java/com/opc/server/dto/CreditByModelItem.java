package com.opc.server.dto;

public record CreditByModelItem(
        String modelName,
        long calls,
        Long inputTokens,
        Long outputTokens,
        long creditsUsed,
        double percent
) {
}
