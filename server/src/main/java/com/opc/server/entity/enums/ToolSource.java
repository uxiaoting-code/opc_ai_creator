package com.opc.server.entity.enums;

/** 能力来源：模型 / 知识库 / MCP / 内置工具。 */
public enum ToolSource {
    MODEL("模型"),
    KNOWLEDGE("知识库"),
    MCP("MCP"),
    BUILTIN("内置");

    private final String label;

    ToolSource(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public static ToolSource parse(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
