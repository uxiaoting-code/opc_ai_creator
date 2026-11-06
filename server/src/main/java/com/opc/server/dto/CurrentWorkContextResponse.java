package com.opc.server.dto;

/**
 * 当前用户工作上下文。
 *
 * <p>Flutter 在登录恢复、刷新和进入创作/工作台时读取一次，
 * 不再通过前端内存猜测当前订单和可执行动作。
 */
public record CurrentWorkContextResponse(
        boolean hasActiveWork,
        MarketOrderResponse order,
        OrderAcceptanceResponse acceptance,
        SubmissionSummaryResponse latestSubmission,
        String action,
        boolean canGenerate,
        boolean canSubmit,
        boolean canAcceptNew,
        String reason
) {
}
