package com.opc.server.entity.enums;

/** 作品提交后的审核状态。 */
public enum ReviewStatus {
    PENDING("审核中"),
    APPROVED("已通过"),
    REJECTED("未通过");

    private final String label;

    ReviewStatus(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public boolean isFinal() {
        return this == APPROVED || this == REJECTED;
    }
}