package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

/** 创建算力充值订单。 */
public record RechargeCreateRequest(
        @NotNull @Positive Long amountFen,
        @NotBlank String channelCode
) {
}