package com.opc.server.dto;

import com.opc.server.entity.WalletTransaction;
import com.opc.server.entity.enums.WalletTransactionType;

import java.time.LocalDateTime;

/** 现金钱包流水响应。 */
public record WalletTransactionResponse(
        Long id,
        String transactionNo,
        WalletTransactionType type,
        String typeLabel,
        Long amountFen,
        Long balanceAfterFen,
        String referenceType,
        Long referenceId,
        String description,
        LocalDateTime createdAt
) {

    public static WalletTransactionResponse from(WalletTransaction transaction) {
        return new WalletTransactionResponse(
                transaction.getId(),
                transaction.getTransactionNo(),
                transaction.getType(),
                transaction.getType() == null ? null : transaction.getType().getLabel(),
                transaction.getAmountFen(),
                transaction.getBalanceAfterFen(),
                transaction.getReferenceType(),
                transaction.getReferenceId(),
                transaction.getDescription(),
                transaction.getCreatedAt());
    }
}