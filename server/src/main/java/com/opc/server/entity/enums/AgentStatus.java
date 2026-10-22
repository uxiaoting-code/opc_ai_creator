package com.opc.server.entity.enums;

/** 智能体状态，对应原型「已发布 / 草稿 / 已下线」。 */
public enum AgentStatus {

    DRAFT("草稿"),
    PUBLISHED("已发布"),
    OFFLINE("已下线");

    private final String label;

    AgentStatus(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public static AgentStatus parse(String value) {
        if (value == null || value.isBlank()) {
            return DRAFT;
        }
        try {
            return valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    public static String labelOf(String value) {
        AgentStatus status = parse(value);
        return status == null ? value : status.getLabel();
    }
}
