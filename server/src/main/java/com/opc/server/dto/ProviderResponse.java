package com.opc.server.dto;

import com.opc.server.entity.AiProviderConfig;
import com.opc.server.entity.enums.PriceUnit;
import com.opc.server.entity.enums.ProviderType;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** 大模型配置列表行，字段与原型「大模型配置」表格列一一对应。 */
public record ProviderResponse(
        Long id,
        String name,
        String vendor,
        String type,
        String typeLabel,
        String channel,
        String modelName,
        String providerImpl,
        BigDecimal inputPrice,
        BigDecimal outputPrice,
        String priceUnit,
        String priceUnitLabel,
        long todayCalls,
        BigDecimal successRate,
        boolean online,
        Integer timeoutSeconds,
        Integer sortOrder,
        String remark,
        LocalDateTime createdAt
) {

    public static ProviderResponse from(AiProviderConfig c) {
        return new ProviderResponse(
                c.getId(),
                c.getName(),
                c.getVendor(),
                c.getType(),
                ProviderType.labelOf(c.getType()),
                c.getChannel(),
                c.getModelName(),
                c.getProviderImpl(),
                c.getInputPrice(),
                c.getOutputPrice(),
                c.getPriceUnit(),
                PriceUnit.labelOf(c.getPriceUnit()),
                // 调用日志表属于 P3 调试面板，P1 先返回 0 / null，前端显示「—」
                0L,
                null,
                c.isOnline(),
                c.getTimeoutSeconds(),
                c.getSortOrder(),
                c.getRemark(),
                c.getCreatedAt()
        );
    }
}
