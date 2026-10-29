package com.opc.server.dto;

import com.opc.server.entity.KnowledgeBase;

import java.time.LocalDateTime;

public record KnowledgeBaseResponse(
        Long id,
        String name,
        String description,
        String embeddingModel,
        String status,
        int documentCount,
        int chunkCount,
        int boundAgentCount,
        LocalDateTime updatedAt
) {

    public static KnowledgeBaseResponse from(KnowledgeBase kb) {
        int bound = 0;
        if (kb.getBoundAgentIds() != null && !kb.getBoundAgentIds().isBlank()) {
            bound = kb.getBoundAgentIds().split(",").length;
        }
        return new KnowledgeBaseResponse(
                kb.getId(), kb.getName(), kb.getDescription(), kb.getEmbeddingModel(),
                kb.getStatus(),
                kb.getDocumentCount() == null ? 0 : kb.getDocumentCount(),
                kb.getChunkCount() == null ? 0 : kb.getChunkCount(),
                bound, kb.getUpdatedAt()
        );
    }
}
