package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;

public record KnowledgeBaseRequest(
        @NotBlank(message = "请填写知识库名称") String name,
        String description,
        String embeddingModel
) {
}
