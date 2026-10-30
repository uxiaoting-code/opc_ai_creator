package com.opc.server.dto;

import com.opc.server.entity.WithdrawRequest;
import com.opc.server.entity.enums.WithdrawStatus;

import java.time.LocalDateTime;

/** 提现申请响应；不返回完整收款账号。 */
public record WithdrawRequestResponse(
        Long id,
        String withdrawNo,
        Long amountFen,
        String channelCode,
        String accountName,
        String accountNoMasked,
        WithdrawStatus status,
        String statusLabel,
        String failureReason,
        LocalDateTime createdAt,
        LocalDateTime processedAt
) {

    public static WithdrawRequestResponse from(WithdrawRequest request) {
        return new WithdrawRequestResponse(
                request.getId(),
                request.getWithdrawNo(),
                request.getAmountFen(),
                request.getChannelCode(),
                request.getAccountName(),
                request.getAccountNoMasked(),
                request.getStatus(),
                request.getStatus() == null ? null : request.getStatus().getLabel(),
                request.getFailureReason(),
                request.getCreatedAt(),
                request.getProcessedAt());
    }
}