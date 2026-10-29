package com.opc.server.dto;

import com.opc.server.entity.CreditTransaction;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record BillResponse(
        Long id,
        String orderNo,
        Long userId,
        String userName,
        String type,
        String typeLabel,
        BigDecimal amount,
        Integer creditsDelta,
        String channel,
        String status,
        String statusLabel,
        LocalDateTime createdAt
) {

    public static BillResponse from(CreditTransaction t, String userName) {
        return new BillResponse(
                t.getId(), t.getOrderNo(), t.getUserId(), userName,
                t.getType(), typeLabel(t.getType()),
                t.getMoneyAmount(), t.getAmount(),
                t.getChannel(), t.getStatus(), statusLabel(t.getStatus()),
                t.getCreatedAt()
        );
    }

    private static String typeLabel(String type) {
        return switch (type == null ? "" : type) {
            case "RECHARGE" -> "充值";
            case "CONSUME" -> "消耗";
            case "REFUND" -> "退款";
            case "GIFT" -> "赠送";
            case "ADMIN_ADJUST" -> "后台调整";
            default -> type;
        };
    }

    private static String statusLabel(String status) {
        return switch (status == null ? "" : status) {
            case "SUCCESS" -> "成功";
            case "PENDING" -> "处理中";
            case "FAILED" -> "失败";
            default -> status;
        };
    }
}
