package com.opc.server.dto;

import java.math.BigDecimal;

public record RechargeRequest(
        Long userId,
        BigDecimal amount,
        String channel,
        String remark
) {
}
