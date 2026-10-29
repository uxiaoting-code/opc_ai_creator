package com.opc.server.dto;

import com.opc.server.entity.MarketOrder;
import com.opc.server.entity.enums.AcceptanceStatus;
import com.opc.server.entity.enums.MarketOrderStatus;
import com.opc.server.entity.enums.MediaType;

import java.time.LocalDateTime;
import java.util.List;

/** 接单市场订单响应。 */
public record MarketOrderResponse(
        Long id,
        String orderNo,
        String title,
        String brandName,
        String description,
        MediaType mediaType,
        Long rewardFen,
        Integer creditCost,
        LocalDateTime deadlineAt,
        Integer tasksTotal,
        Integer tasksTaken,
        List<String> requirements,
        MarketOrderStatus status,
        AcceptanceStatus myAcceptanceStatus,
        LocalDateTime createdAt
) {

    public static MarketOrderResponse from(MarketOrder order, AcceptanceStatus myAcceptanceStatus) {
        return new MarketOrderResponse(
                order.getId(),
                order.getOrderNo(),
                order.getTitle(),
                order.getBrandName(),
                order.getDescription(),
                order.getMediaType(),
                order.getRewardFen(),
                order.getCreditCost(),
                order.getDeadlineAt(),
                order.getTasksTotal(),
                order.getTasksTaken(),
                order.getRequirements() == null ? List.of() : List.copyOf(order.getRequirements()),
                order.getStatus(),
                myAcceptanceStatus,
                order.getCreatedAt());
    }
}