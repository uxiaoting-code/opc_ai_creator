package com.opc.server.dto;

import com.opc.server.entity.OrderAcceptance;
import com.opc.server.entity.enums.AcceptanceStatus;

import java.time.LocalDateTime;

/** 当前用户的接单记录。 */
public record OrderAcceptanceResponse(
        Long id,
        String acceptanceNo,
        Long orderId,
        Long userId,
        AcceptanceStatus status,
        LocalDateTime acceptedAt,
        LocalDateTime submittedAt,
        LocalDateTime approvedAt
) {

    public static OrderAcceptanceResponse from(OrderAcceptance acceptance) {
        return new OrderAcceptanceResponse(
                acceptance.getId(),
                acceptance.getAcceptanceNo(),
                acceptance.getOrderId(),
                acceptance.getUserId(),
                acceptance.getStatus(),
                acceptance.getAcceptedAt(),
                acceptance.getSubmittedAt(),
                acceptance.getApprovedAt());
    }
}