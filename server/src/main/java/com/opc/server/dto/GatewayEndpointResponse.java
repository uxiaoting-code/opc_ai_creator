package com.opc.server.dto;

import com.opc.server.entity.GatewayEndpoint;

import java.time.LocalDateTime;

public record GatewayEndpointResponse(
        Long id,
        String name,
        String method,
        String path,
        Long agentId,
        boolean authRequired,
        String rateLimit,
        boolean online,
        long callCount,
        String remark,
        LocalDateTime updatedAt
) {

    public static GatewayEndpointResponse from(GatewayEndpoint e) {
        return new GatewayEndpointResponse(
                e.getId(), e.getName(), e.getMethod(), e.getPath(), e.getAgentId(),
                Boolean.TRUE.equals(e.getAuthRequired()), e.getRateLimit(),
                Boolean.TRUE.equals(e.getOnline()),
                e.getCallCount() == null ? 0L : e.getCallCount(),
                e.getRemark(), e.getUpdatedAt()
        );
    }
}
