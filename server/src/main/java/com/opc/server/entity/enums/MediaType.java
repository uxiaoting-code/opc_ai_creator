package com.opc.server.entity.enums;

/** 用户端订单和提交支持的媒体类型。 */
public enum MediaType {
    IMAGE("图片"),
    VIDEO("视频"),
    AUDIO("音频");

    private final String label;

    MediaType(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}