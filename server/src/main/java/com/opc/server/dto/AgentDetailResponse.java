package com.opc.server.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/** 智能体详情：基础信息 + 计费 + 编排节点。 */
public record AgentDetailResponse(
        Long id,
        String name,
        String code,
        String category,
        String categoryLabel,
        String description,
        String icon,
        Long modelProviderId,
        String modelProviderName,
        String systemPrompt,
        String greeting,
        Billing billing,
        List<AgentNodeResponse> nodes,
        String status,
        String statusLabel,
        int currentVersion,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {

    public record Billing(
            BigDecimal baseCost,
            Integer maxRounds,
            Integer timeoutSeconds,
            Integer dailyQuota,
            Boolean allowUserSkill,
            Boolean logFullConversation
    ) {
    }
}
