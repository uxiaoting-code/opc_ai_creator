package com.opc.server.dto;

import java.time.LocalDateTime;

public record McpServerResponse(
        Long id,
        String name,
        String transport,
        String endpoint,
        String status,
        LocalDateTime lastDiscoverAt,
        int toolCount,
        long enabledToolCount,
        LocalDateTime createdAt
) {
}
