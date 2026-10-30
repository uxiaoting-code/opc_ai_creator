package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

/** 创建提现申请。 */
public record WithdrawCreateRequest(
        @NotNull @Positive Long amountFen,
        @NotBlank String channelCode,
        @NotBlank @Size(max = 100) String accountName,
        @NotBlank @Size(max = 100) String accountNo
) {
}