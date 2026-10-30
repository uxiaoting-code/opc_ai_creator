package com.opc.server.entity.enums;

/** 现金钱包流水类型。 */
public enum WalletTransactionType {
    ORDER_INCOME("订单收入"),
    WITHDRAW_FREEZE("提现冻结"),
    WITHDRAW_SUCCESS("提现成功"),
    WITHDRAW_REFUND("提现退回"),
    MANUAL_ADJUST("人工调整");

    private final String label;

    WalletTransactionType(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}