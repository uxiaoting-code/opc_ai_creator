package com.opc.server.dto;

import com.opc.server.entity.McpTool;

import java.time.LocalDateTime;

public record McpToolResponse(
        Long id,
        Long serverId,
        String toolName,
        String toolKey,
        String displayName,
        String description,
        String inputSchema,
        boolean enabled,
        LocalDateTime lastInvokedAt
) {

    public static McpToolResponse from(McpTool tool) {
        return new McpToolResponse(
                tool.getId(), tool.getServerId(), tool.getToolName(), tool.getToolKey(),
                tool.getDisplayName(), tool.getDescription(), tool.getInputSchema(),
                Boolean.TRUE.equals(tool.getEnabled()), tool.getLastInvokedAt()
        );
    }
}
