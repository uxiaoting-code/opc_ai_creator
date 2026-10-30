package com.opc.server.entity.enums;

/** 算力充值订单状态。 */
public enum RechargeOrderStatus {
    PENDING("待支付"),
    PAID("已支付"),
    FAILED("支付失败"),
    CLOSED("已关闭"),
    REFUNDED("已退款");

    private final String label;

    RechargeOrderStatus(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}