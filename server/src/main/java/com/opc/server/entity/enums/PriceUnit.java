package com.opc.server.entity.enums;

/** 计价单位，对应原型「大模型配置」页的价格列。 */
public enum PriceUnit {

    TOKEN("百万token"),
    SECOND("秒"),
    CALL("次");

    private final String label;

    PriceUnit(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public static PriceUnit parse(String value) {
        if (value == null || value.isBlank()) {
            return TOKEN;
        }
        try {
            return valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    public static String labelOf(String value) {
        PriceUnit unit = parse(value);
        return unit == null ? value : unit.getLabel();
    }
}
