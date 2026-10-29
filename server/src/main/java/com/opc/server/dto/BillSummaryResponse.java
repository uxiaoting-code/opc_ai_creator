package com.opc.server.dto;

import java.math.BigDecimal;

public record BillSummaryResponse(
        long count,
        BigDecimal totalRecharge,
        BigDecimal totalConsume
) {
}
