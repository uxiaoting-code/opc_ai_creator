package com.opc.server.dto;

public record CreditStatsResponse(
        long todayUsed,
        Double todayDelta,
        long yesterdayUsed,
        long monthUsed,
        Double monthDelta,
        long platformStock,
        Integer stockDays
) {
}
