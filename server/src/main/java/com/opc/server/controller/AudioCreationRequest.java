package com.opc.server.controller;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

/** 文本转音频请求。 */
public record AudioCreationRequest(
        Long skillId,

        @NotBlank @Size(max = 2000) String prompt,

        @NotBlank @Size(max = 50) String voiceCode,

        @NotBlank @Size(max = 20) String language,

        @DecimalMin("0.5") @DecimalMax("2.0") BigDecimal speed,

        @Size(max = 10) String format,

        /** 关联的接单订单 ID；工作台生成时必填。 */
        Long orderId
) {
}