package com.opc.server.dto;

/**
 * 收藏切换后的最新状态。
 */
public record PromptFavoriteResponse(
        Long promptId,
        boolean favorited,
        int favoriteCount
) {
}
