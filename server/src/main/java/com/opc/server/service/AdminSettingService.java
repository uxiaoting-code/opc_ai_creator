package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.SystemSettingRequest;
import com.opc.server.dto.SystemSettingResponse;
import com.opc.server.entity.SystemSetting;
import com.opc.server.entity.User;
import com.opc.server.repository.SystemSettingRepository;
import com.opc.server.repository.UserRepository;
import com.opc.server.security.UserContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * 管理端系统设置服务。
 *
 * <p>配置表采用单行懒初始化：第一次 GET 或 PUT 时自动写入默认值，不需要额外
 * 的启动脚本或手工 SQL。
 */
@Service
public class AdminSettingService {

    private static final int MAX_PLATFORM_NAME_LENGTH = 100;
    private static final int MAX_ANNOUNCEMENT_LENGTH = 2000;
    private static final int MAX_SIGNUP_BONUS = 1_000_000_000;
    private static final int MAX_GENERATION_COST = 1_000_000;
    private static final BigDecimal MAX_MONEY = new BigDecimal("1000000.00");
    private static final BigDecimal ONE_HUNDRED = new BigDecimal("100");

    private final SystemSettingRepository settingRepository;
    private final UserRepository userRepository;

    public AdminSettingService(
            SystemSettingRepository settingRepository,
            UserRepository userRepository) {
        this.settingRepository = settingRepository;
        this.userRepository = userRepository;
    }

    /** 读取全部设置；首次访问时创建默认配置行。 */
    @Transactional
    public SystemSettingResponse getSettings() {
        return SystemSettingResponse.from(loadOrCreate());
    }

    /** 部分或整体更新设置。 */
    @Transactional
    public SystemSettingResponse updateSettings(SystemSettingRequest request) {
        requireAdmin();
        if (request == null || request.isEmpty()) {
            throw new BizException(ErrorCode.ADMIN_SETTING_EMPTY_UPDATE);
        }
        validate(request);

        SystemSetting setting = loadOrCreate();
        if (request.platformName() != null) {
            setting.setPlatformName(request.platformName().trim());
        }
        if (request.signupBonusCredits() != null) {
            setting.setSignupBonusCredits(request.signupBonusCredits());
        }
        if (request.generationCostCredits() != null) {
            setting.setGenerationCostCredits(request.generationCostCredits());
        }
        if (request.rechargeBonusPercent() != null) {
            setting.setRechargeBonusPercent(request.rechargeBonusPercent());
        }
        if (request.creditPrice() != null) {
            setting.setCreditPrice(request.creditPrice());
        }
        if (request.announcement() != null) {
            setting.setAnnouncement(request.announcement().trim());
        }
        if (request.announcementEnabled() != null) {
            setting.setAnnouncementEnabled(request.announcementEnabled());
        }
        if (request.signupEnabled() != null) {
            setting.setSignupEnabled(request.signupEnabled());
        }
        if (request.rechargeEnabled() != null) {
            setting.setRechargeEnabled(request.rechargeEnabled());
        }
        if (request.maintenanceMode() != null) {
            setting.setMaintenanceMode(request.maintenanceMode());
        }
        if (request.aiDebugLogEnabled() != null) {
            setting.setAiDebugLogEnabled(request.aiDebugLogEnabled());
        }

        return SystemSettingResponse.from(settingRepository.save(setting));
    }

    private SystemSetting loadOrCreate() {
        return settingRepository.findById(SystemSetting.SINGLETON_ID)
                .orElseGet(() -> settingRepository.save(SystemSetting.defaults()));
    }

    private void validate(SystemSettingRequest request) {
        if (request.platformName() != null) {
            String platformName = request.platformName().trim();
            if (platformName.isEmpty()
                    || platformName.length() > MAX_PLATFORM_NAME_LENGTH) {
                throw invalid("平台名称长度必须为 1-100 个字符");
            }
        }
        if (request.signupBonusCredits() != null
                && (request.signupBonusCredits() < 0
                || request.signupBonusCredits() > MAX_SIGNUP_BONUS)) {
            throw invalid("默认赠送算力必须在 0-1000000000 之间");
        }
        if (request.generationCostCredits() != null
                && (request.generationCostCredits() < 1
                || request.generationCostCredits() > MAX_GENERATION_COST)) {
            throw invalid("单次生成消耗必须在 1-1000000 之间");
        }
        if (request.rechargeBonusPercent() != null
                && (request.rechargeBonusPercent().compareTo(BigDecimal.ZERO) < 0
                || request.rechargeBonusPercent().compareTo(ONE_HUNDRED) > 0)) {
            throw invalid("充值赠送比例必须在 0-100 之间");
        }
        if (request.creditPrice() != null
                && (request.creditPrice().compareTo(BigDecimal.ZERO) < 0
                || request.creditPrice().compareTo(MAX_MONEY) > 0)) {
            throw invalid("算力单价必须在 0-1000000 之间");
        }
        if (request.announcement() != null
                && request.announcement().length() > MAX_ANNOUNCEMENT_LENGTH) {
            throw invalid("公告内容不能超过 2000 个字符");
        }
    }

    private void requireAdmin() {
        Long userId = UserContext.require();
        User user = userRepository.findByIdAndDeletedFalse(userId)
                .orElseThrow(() -> new BizException(ErrorCode.ADMIN_SETTING_FORBIDDEN));
        if (!"ADMIN".equalsIgnoreCase(user.getRole())) {
            throw BizException.forbidden(ErrorCode.ADMIN_SETTING_FORBIDDEN);
        }
    }

    private static BizException invalid(String message) {
        return new BizException(ErrorCode.ADMIN_SETTING_PARAMETER_INVALID, message);
    }
}
