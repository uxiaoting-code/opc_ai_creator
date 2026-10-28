package com.opc.server.dto;

import java.time.LocalDateTime;
import java.util.List;

public record MaterialVersionResponse(
        Long id,
        Long materialId,
        Integer version,
        String title,
        Long categoryId,
        String categoryName,
        List<Long> tagIds,
        List<String> tagNames,
        String fileUrl,
        String thumbUrl,
        String mimeType,
        String mediaType,
        Long fileSize,
        Integer width,
        Integer height,
        String changeNote,
        LocalDateTime createdAt
) {
}
