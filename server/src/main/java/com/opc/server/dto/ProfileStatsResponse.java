package com.opc.server.dto;

import java.util.Map;

/** 个人中心统一统计响应；钱包继续以分为单位，算力单独使用 credits。 */
public record ProfileStatsResponse(
        Integer credits,
        Long withdrawableFen,
        Long frozenFen,
        Long totalIncomeFen,
        Long totalWithdrawnFen,
        Long pendingReviewCount,
        Long approvedReviewCount,
        Long rejectedReviewCount,
        Map<String, Long> taskStats
) {
}