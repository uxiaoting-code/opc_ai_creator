package com.opc.server.dto;

import com.opc.server.entity.Material;
import com.opc.server.entity.MaterialTag;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

/**
 * 管理端素材响应。C 端仍使用原有的 {@link MaterialResponse}。
 */
public record MaterialAdminResponse(
        Long id,
        String title,
        Long categoryId,
        String categoryName,
        String categoryPath,
        List<TagRef> tags,
        String fileUrl,
        String thumbUrl,
        String mimeType,
        String mediaType,
        Long fileSize,
        Integer width,
        Integer height,
        int version,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {

    public record TagRef(Long id, String name, Long parentId) {
    }

    public static MaterialAdminResponse from(
            Material material,
            String categoryName,
            String categoryPath) {
        List<TagRef> tags = material.getTags() == null
                ? List.of()
                : material.getTags().stream()
                        .sorted(Comparator.comparing(MaterialTag::getId))
                        .map(tag -> new TagRef(tag.getId(), tag.getName(), tag.getParentId()))
                        .toList();
        return new MaterialAdminResponse(
                material.getId(),
                titleOf(material),
                material.getCategoryId(),
                categoryName,
                categoryPath,
                tags,
                material.getUrl(),
                material.getThumbUrl(),
                material.getMimeType(),
                mediaTypeOf(material.getMimeType()),
                material.getFileSize(),
                material.getWidth(),
                material.getHeight(),
                material.getVersion() == null ? 1 : material.getVersion(),
                material.getCreatedAt(),
                material.getUpdatedAt()
        );
    }

    public static String titleOf(Material material) {
        if (material == null) {
            return null;
        }
        return material.getTitle() == null || material.getTitle().isBlank()
                ? material.getName()
                : material.getTitle();
    }

    public static String mediaTypeOf(String mimeType) {
        if (mimeType == null) {
            return "OTHER";
        }
        String value = mimeType.toLowerCase();
        if (value.startsWith("image/")) {
            return "IMAGE";
        }
        if (value.startsWith("video/")) {
            return "VIDEO";
        }
        if (value.startsWith("audio/")) {
            return "AUDIO";
        }
        return "OTHER";
    }
}
