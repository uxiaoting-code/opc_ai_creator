package com.opc.server.dto;

import java.math.BigDecimal;

public record OverviewResponse(
        long totalUsers,
        Double totalUsersDelta,
        long activeUsersToday,
        Double activeUsersDelta,
        BigDecimal revenueToday,
        Double revenueDelta,
        long creditsUsedToday,
        Double creditsUsedDelta
) {
}
