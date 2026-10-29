package com.opc.server.dto;

/** 接单成功后返回接单记录和工作台上下文。 */
public record AcceptOrderResponse(
        OrderAcceptanceResponse acceptance,
        WorkbenchContextResponse workbench
) {
}