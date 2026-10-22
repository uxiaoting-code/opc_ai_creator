package com.opc.server.dto;

import com.opc.server.entity.AiProviderConfig;
import com.opc.server.entity.enums.PriceUnit;
import com.opc.server.entity.enums.ProviderType;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** 大模型配置详情：基础信息 + 鉴权 + 请求/响应模板。密钥只返回脱敏值。 */
public record ProviderDetailResponse(
        Long id,
        String name,
        String vendor,
        String type,
        String typeLabel,
        String channel,
        String modelName,
        String baseUrl,
        String providerImpl,
        String authType,
        String apiKeyMasked,
        String headerName,
        String headerValue,
        String oauthTokenUrl,
        String oauthClientId,
        String requestMethod,
        String requestPath,
        String requestContentType,
        String requestQueryJson,
        String requestHeadersJson,
        String requestBodyJson,
        String responseSuccessPath,
        String responseResultUrlPath,
        String responseThumbPath,
        String responseErrorPath,
        String responseTaskIdPath,
        BigDecimal inputPrice,
        BigDecimal outputPrice,
        String priceUnit,
        String priceUnitLabel,
        Integer timeoutSeconds,
        boolean online,
        Integer sortOrder,
        String remark,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {

    public static ProviderDetailResponse from(AiProviderConfig c) {
        return new ProviderDetailResponse(
                c.getId(), c.getName(), c.getVendor(), c.getType(),
                ProviderType.labelOf(c.getType()), c.getChannel(), c.getModelName(),
                c.getBaseUrl(), c.getProviderImpl(), c.getAuthType(), mask(c.getApiKey()),
                c.getHeaderName(), c.getHeaderValue(), c.getOauthTokenUrl(),
                c.getOauthClientId(), c.getRequestMethod(), c.getRequestPath(),
                c.getRequestContentType(), c.getRequestQueryJson(), c.getRequestHeadersJson(),
                c.getRequestBodyJson(), c.getResponseSuccessPath(), c.getResponseResultUrlPath(),
                c.getResponseThumbPath(), c.getResponseErrorPath(), c.getResponseTaskIdPath(),
                c.getInputPrice(), c.getOutputPrice(), c.getPriceUnit(),
                PriceUnit.labelOf(c.getPriceUnit()), c.getTimeoutSeconds(), c.isOnline(),
                c.getSortOrder(), c.getRemark(), c.getCreatedAt(), c.getUpdatedAt()
        );
    }

    private static String mask(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        if (value.length() <= 4) {
            return "****";
        }
        return "****" + value.substring(value.length() - 4);
    }
}
