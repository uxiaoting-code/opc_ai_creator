package com.opc.server.entity.enums;

/** 提现申请状态。 */
public enum WithdrawStatus {
    PENDING("待处理"),
    PROCESSING("处理中"),
    SUCCESS("已到账"),
    FAILED("提现失败"),
    CANCELLED("已取消");

    private final String label;

    WithdrawStatus(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public boolean isTerminal() {
        return this == SUCCESS || this == FAILED || this == CANCELLED;
    }
}