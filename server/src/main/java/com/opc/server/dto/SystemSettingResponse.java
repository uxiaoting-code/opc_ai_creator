package com.opc.server.dto;

import com.opc.server.entity.SystemSetting;

import java.math.BigDecimal;

public record SystemSettingResponse(
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

    public static SystemSettingResponse from(SystemSetting setting) {
        return new SystemSettingResponse(
                setting.getPlatformName(),
                setting.getSignupBonusCredits(),
                setting.getGenerationCostCredits(),
                setting.getRechargeBonusPercent(),
                setting.getCreditPrice(),
                setting.getAnnouncement(),
                setting.getAnnouncementEnabled(),
                setting.getSignupEnabled(),
                setting.getRechargeEnabled(),
                setting.getMaintenanceMode(),
                setting.getAiDebugLogEnabled()
        );
    }
}
