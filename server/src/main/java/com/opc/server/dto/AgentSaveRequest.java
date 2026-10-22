package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;

/**
 * 保存编排（原型「保存编排」按钮）。
 *
 * <p>nodes 是<b>全量数组</b>：服务端按 nodeKey 对齐增删改。
 */
public record AgentSaveRequest(
        @NotBlank(message = "请填写智能体名称")
        @Size(max = 100, message = "名称最多 100 字")
        String name,

        @NotBlank(message = "请填写智能体标识")
        @Size(max = 50, message = "标识最多 50 字")
        String code,

        @Size(max = 30, message = "分类最多 30 字")
        String category,

        @Size(max = 500, message = "描述最多 500 字")
        String description,

        @Size(max = 20, message = "图标最多 20 字")
        String icon,

        Long modelProviderId,
        String systemPrompt,
        String greeting,
        Billing billing,
        List<Node> nodes
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

    public record Node(
            String nodeKey,
            String name,
            Integer orderIndex,
            Boolean enabled,
            String toolSource,
            Long toolRefId,
            String toolKey,
            String toolNameSnapshot,
            String paramsJson,
            String routeKeywords,
            String routeTargetKey
    ) {
    }
}
