package com.opc.server.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** 智能体列表行，字段对应原型「智能体列表」表格列。 */
public record AgentResponse(
        Long id,
        String name,
        String code,
        String category,
        String categoryLabel,
        String description,
        String icon,
        Long modelProviderId,
        long modelCount,
        int skillCount,
        int enabledSkillCount,
        long todayCalls,
        Long avgElapsedMs,
        BigDecimal successRate,
        String status,
        String statusLabel,
        int currentVersion,
        LocalDateTime updatedAt
) {
}
