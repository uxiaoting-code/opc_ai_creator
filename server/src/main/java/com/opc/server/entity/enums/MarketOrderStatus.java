package com.opc.server.entity.enums;

/** 订单在整个接单市场中的公共状态，不是单个用户的状态。 */
public enum MarketOrderStatus {
    OPEN("可接单"),
    CLOSED("已关闭"),
    COMPLETED("已完成");

    private final String label;

    MarketOrderStatus(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}