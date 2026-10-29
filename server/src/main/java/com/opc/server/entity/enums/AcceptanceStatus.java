package com.opc.server.entity.enums;

/** 当前用户针对某个订单的接单状态。 */
public enum AcceptanceStatus {
    ACCEPTED("制作中"),
    SUBMITTED("待审核"),
    APPROVED("审核通过"),
    REJECTED("审核驳回"),
    CANCELLED("已取消");

    private final String label;

    AcceptanceStatus(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}