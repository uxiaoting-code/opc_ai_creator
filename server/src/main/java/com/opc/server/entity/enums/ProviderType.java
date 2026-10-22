package com.opc.server.entity.enums;

/** 模型类型，对应原型「大模型配置」页的类型徽章。 */
public enum ProviderType {

    CHAT("聊天"),
    IMAGE("图片"),
    VIDEO("视频"),
    AUDIO("音频");

    private final String label;

    ProviderType(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    /** 不区分大小写解析；非法值返回 null，由 Service 统一抛参数错误。 */
    public static ProviderType parse(String value) {
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
        ProviderType type = parse(value);
        return type == null ? value : type.getLabel();
    }
}
