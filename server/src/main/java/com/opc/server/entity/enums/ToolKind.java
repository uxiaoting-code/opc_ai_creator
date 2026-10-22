package com.opc.server.entity.enums;

/** 能力类型，直接对应原型「添加 Skill」弹窗的 8 个选项。 */
public enum ToolKind {

    MODEL_CALL("模型调用"),
    WEB_SEARCH("联网搜索"),
    KB_RETRIEVE("知识库检索"),
    CODE_RUN("代码执行"),
    IMAGE_PROCESS("图像处理"),
    DB_QUERY("数据查询"),
    HTTP_REQUEST("HTTP 请求"),
    HUMAN_REVIEW("人工审核");

    private final String label;

    ToolKind(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public static ToolKind parse(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    public static String labelOf(String value) {
        ToolKind kind = parse(value);
        return kind == null ? value : kind.getLabel();
    }
}
