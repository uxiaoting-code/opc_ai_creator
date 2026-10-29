package com.opc.server.dto;

/** 订单详情：公共订单 + 当前用户接单状态。 */
public record OrderDetailResponse(
        MarketOrderResponse order,
        OrderAcceptanceResponse myAcceptance,
        boolean canAccept,
        String unavailableReason
) {
}