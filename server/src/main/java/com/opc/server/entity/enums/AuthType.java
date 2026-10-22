package com.opc.server.entity.enums;

/** 模型鉴权方式，对应需求 3.1 第 2 步。 */
public enum AuthType {
    NONE,
    API_KEY,
    OAUTH,
    CUSTOM_HEADER;

    public static AuthType parse(String value) {
        if (value == null || value.isBlank()) {
            return NONE;
        }
        try {
            return valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
