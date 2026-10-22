package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

/** 新增 / 修改模型的基础信息。 */
public record ProviderCreateRequest(
        @NotBlank(message = "请填写模型名称")
        @Size(max = 100, message = "模型名称最多 100 字")
        String name,

        @Size(max = 50, message = "厂商最多 50 字")
        String vendor,

        @NotBlank(message = "请选择模型类型")
        String type,

        @Size(max = 50, message = "渠道标识最多 50 字")
        String channel,

        @Size(max = 100, message = "模型名最多 100 字")
        String modelName,

        @Size(max = 255, message = "服务地址最多 255 字")
        String baseUrl,

        String providerImpl,
        BigDecimal inputPrice,
        BigDecimal outputPrice,
        String priceUnit,
        Integer timeoutSeconds,
        Integer sortOrder,

        @Size(max = 500, message = "备注最多 500 字")
        String remark
) {
}
