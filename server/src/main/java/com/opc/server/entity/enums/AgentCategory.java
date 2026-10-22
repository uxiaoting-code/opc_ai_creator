package com.opc.server.entity.enums;

/** 智能体分类，对应原型分类下拉。 */
public enum AgentCategory {

    CUSTOMER_SERVICE("客服"),
    MARKETING("营销"),
    DESIGN("设计"),
    DATA_ANALYSIS("数据分析"),
    OTHER("其他");

    private final String label;

    AgentCategory(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public static AgentCategory parse(String value) {
        if (value == null || value.isBlank()) {
            return OTHER;
        }
        try {
            return valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    public static String labelOf(String value) {
        AgentCategory category = parse(value);
        return category == null ? value : category.getLabel();
    }
}
