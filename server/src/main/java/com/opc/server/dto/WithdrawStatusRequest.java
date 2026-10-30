package com.opc.server.dto;

import com.opc.server.entity.enums.WithdrawStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** 后台更新提现状态。 */
public record WithdrawStatusRequest(
        @NotNull WithdrawStatus status,
        @Size(max = 500) String failureReason,
        @Size(max = 100) String externalTradeNo
) {
}