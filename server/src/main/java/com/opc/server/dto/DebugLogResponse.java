package com.opc.server.dto;

import com.opc.server.entity.CallLog;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record DebugLogResponse(
        Long id,
        String sessionId,
        Long agentId,
        String agentName,
        String mode,
        Long nodeId,
        String nodeKey,
        String nodeName,
        String toolKind,
        String input,
        String output,
        boolean success,
        String status,
        Long elapsedMs,
        BigDecimal credits,
        String errorMessage,
        String operator,
        LocalDateTime createdAt
) {

    public static DebugLogResponse from(CallLog log) {
        return new DebugLogResponse(
                log.getId(), log.getSessionId(), log.getAgentId(), log.getAgentName(),
                log.getMode(), log.getNodeId(), log.getNodeKey(), log.getNodeName(),
                log.getToolKind(), log.getInput(), log.getOutput(),
                Boolean.TRUE.equals(log.getSuccess()),
                Boolean.TRUE.equals(log.getSuccess()) ? "SUCCESS" : "FAILED",
                log.getElapsedMs(), log.getCredits(),
                log.getErrorMsg(), log.getOperator(), log.getCreatedAt()
        );
    }
}
