package com.opc.server.dto;

import com.opc.server.entity.Material;

import java.time.LocalDateTime;

/**
 * 素材响应。
 *
 * <p>前端上传首帧参考图后只需要拿到 {@code url} 去创建任务，
 * 但其余字段一并返回，将来做「素材库」页面时不用再改接口。
 *
 * <p>与其它响应 DTO 一样是显式 record 而不是直接序列化实体：
 * 实体里带着 {@code deleted} 之类的内部字段，暴露出去没有意义。
 */
public record MaterialResponse(
        Long id,
        String name,
        String url,
        String thumbUrl,
        Long fileSize,
        String mimeType,
        Integer width,
        Integer height,
        String source,
        LocalDateTime createdAt
) {

    public static MaterialResponse from(Material material) {
        if (material == null) {
            return null;
        }
        return new MaterialResponse(
                material.getId(),
                material.getName(),
                material.getUrl(),
                material.getThumbUrl(),
                material.getFileSize(),
                material.getMimeType(),
                material.getWidth(),
                material.getHeight(),
                material.getSource(),
                material.getCreatedAt()
        );
    }
}
