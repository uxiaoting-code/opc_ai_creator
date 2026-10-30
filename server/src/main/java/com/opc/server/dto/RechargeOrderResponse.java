package com.opc.server.dto;

import com.opc.server.entity.RechargeOrder;
import com.opc.server.entity.enums.RechargeOrderStatus;

import java.time.LocalDateTime;

/** 算力充值订单响应。 */
public record RechargeOrderResponse(
        Long id,
        String rechargeNo,
        Long amountFen,
        Integer credits,
        String channelCode,
        RechargeOrderStatus status,
        String statusLabel,
        String payUrl,
        LocalDateTime createdAt,
        LocalDateTime paidAt
) {

    public static RechargeOrderResponse from(RechargeOrder order) {
        return new RechargeOrderResponse(
                order.getId(),
                order.getRechargeNo(),
                order.getAmountFen(),
                order.getCredits(),
                order.getChannelCode(),
                order.getStatus(),
                order.getStatus() == null ? null : order.getStatus().getLabel(),
                order.getPayUrl(),
                order.getCreatedAt(),
                order.getPaidAt());
    }
}