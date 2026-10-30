package com.opc.server.entity.enums;

/** 支付渠道支持的交易方向。 */
public enum PaymentChannelDirection {
    RECHARGE("充值"),
    WITHDRAW("提现"),
    BOTH("充值/提现");

    private final String label;

    PaymentChannelDirection(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public boolean supportsRecharge() {
        return this == RECHARGE || this == BOTH;
    }

    public boolean supportsWithdraw() {
        return this == WITHDRAW || this == BOTH;
    }
}