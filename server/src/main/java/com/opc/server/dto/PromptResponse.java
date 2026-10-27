package com.opc.server.dto;

import com.opc.server.entity.Prompt;

import java.time.LocalDateTime;

/**
 * Prompt 知识库条目响应。
 */
public record PromptResponse(
        Long id,
        Long userId,
        String title,
        String content,
        String negativeContent,
        String category,
        String tags,
        String coverUrl,
        int favoriteCount,
        int useCount,
        boolean isPublic,
        boolean favorited,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {

    public static PromptResponse from(Prompt prompt, boolean favorited) {
        return new PromptResponse(
                prompt.getId(),
                prompt.getUserId(),
                prompt.getTitle(),
                prompt.getContent(),
                prompt.getNegativeContent(),
                prompt.getCategory(),
                prompt.getTags(),
                prompt.getCoverUrl(),
                value(prompt.getFavoriteCount()),
                value(prompt.getUseCount()),
                prompt.getIsPublic() != null && prompt.getIsPublic() == 1,
                favorited,
                prompt.getCreatedAt(),
                prompt.getUpdatedAt()
        );
    }

    private static int value(Integer number) {
        return number == null ? 0 : number;
    }
}
