package com.opc.server.dto;

/** 用户钱包汇总。 */
public record WalletSummaryResponse(
        Long withdrawableFen,
        Long frozenFen,
        Long totalIncomeFen,
        Long totalWithdrawnFen,
        Integer credits
) {
}