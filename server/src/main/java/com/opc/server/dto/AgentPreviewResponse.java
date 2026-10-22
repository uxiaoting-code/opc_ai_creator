package com.opc.server.dto;

import java.math.BigDecimal;
import java.util.List;

/** 编排预览的执行轨迹（P2 先做模拟轨迹，不扣真实算力）。 */
public record AgentPreviewResponse(
        String sessionId,
        long totalElapsedMs,
        BigDecimal totalCredits,
        boolean success,
        String finalOutput,
        List<Step> nodes
) {

    public record Step(
            Long nodeId,
            String nodeKey,
            String name,
            String toolKind,
            boolean success,
            long elapsedMs,
            BigDecimal credits,
            String input,
            String output,
            String errorMessage
    ) {
    }
}
