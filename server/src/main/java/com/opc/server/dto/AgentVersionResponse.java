package com.opc.server.dto;

import java.time.LocalDateTime;

public record AgentVersionResponse(
        Integer versionNo,
        String remark,
        String operator,
        LocalDateTime createdAt
) {
}
