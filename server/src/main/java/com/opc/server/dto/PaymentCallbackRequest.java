package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.LocalDateTime;

/** 支付渠道服务端回调。signature 由渠道签名或开发期共享密钥生成。 */
public record PaymentCallbackRequest(
        @NotBlank String rechargeNo,
        @NotBlank String externalTradeNo,
        @NotNull @Positive Long paidFen,
        LocalDateTime paidAt,
        @NotBlank String signature
) {
}