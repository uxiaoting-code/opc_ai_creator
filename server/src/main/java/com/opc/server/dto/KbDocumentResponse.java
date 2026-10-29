package com.opc.server.dto;

import com.opc.server.entity.KbDocument;

import java.time.LocalDateTime;

public record KbDocumentResponse(
        Long id,
        Long kbId,
        String name,
        String sourceType,
        String sourceUrl,
        String mimeType,
        Long fileSize,
        int chunkCount,
        String status,
        String errorMessage,
        LocalDateTime createdAt
) {

    public static KbDocumentResponse from(KbDocument doc) {
        return new KbDocumentResponse(
                doc.getId(), doc.getKbId(), doc.getName(), doc.getSourceType(),
                doc.getSourceUrl(), doc.getMimeType(), doc.getFileSize(),
                doc.getChunkCount() == null ? 0 : doc.getChunkCount(),
                doc.getStatus(), doc.getErrorMsg(), doc.getCreatedAt()
        );
    }
}
