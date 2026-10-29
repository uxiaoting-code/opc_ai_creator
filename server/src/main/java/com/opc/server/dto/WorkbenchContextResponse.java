package com.opc.server.dto;

import com.opc.server.entity.enums.MediaType;

/** 工作台上下文：订单、当前接单和是否允许继续生成。 */
public record WorkbenchContextResponse(
        MarketOrderResponse order,
        OrderAcceptanceResponse acceptance,
        MediaType recommendedMediaType,
        SubmissionSummaryResponse activeSubmission,
        boolean canGenerate,
        String unavailableReason
) {
}