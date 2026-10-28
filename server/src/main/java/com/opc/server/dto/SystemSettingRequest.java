package com.opc.server.dto;

import java.math.BigDecimal;

/**
 * 系统设置更新请求。
 *
 * <p>所有字段都可为空；为空的字段表示本次不修改，因此同一个 PUT 接口既能
 * 提交整张表单，也能只更新一个开关。
 */
public record SystemSettingRequest(
        String platformName,
        Integer signupBonusCredits,
        Integer generationCostCredits,
        BigDecimal rechargeBonusPercent,
        BigDecimal creditPrice,
        String announcement,
        Boolean announcementEnabled,
        Boolean signupEnabled,
        Boolean rechargeEnabled,
        Boolean maintenanceMode,
        Boolean aiDebugLogEnabled
) {

    public boolean isEmpty() {
        return platformName == null
                && signupBonusCredits == null
                && generationCostCredits == null
                && rechargeBonusPercent == null
                && creditPrice == null
                && announcement == null
                && announcementEnabled == null
                && signupEnabled == null
                && rechargeEnabled == null
                && maintenanceMode == null
                && aiDebugLogEnabled == null;
    }
}
