package com.opc.server;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.RegisterRequest;
import com.opc.server.dto.SystemSettingRequest;
import com.opc.server.entity.User;
import com.opc.server.repository.SystemSettingRepository;
import com.opc.server.repository.UserRepository;
import com.opc.server.security.PasswordEncoder;
import com.opc.server.security.TokenService;
import com.opc.server.security.UserContext;
import com.opc.server.service.AdminSettingService;
import com.opc.server.service.AuthService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
class AdminSettingServiceDataTest {

    @Autowired
    private SystemSettingRepository settingRepository;

    @Autowired
    private UserRepository userRepository;

    private final PasswordEncoder passwordEncoder = new PasswordEncoder();

    @AfterEach
    void clearUserContext() {
        UserContext.clear();
    }

    @Test
    void readsDefaultsAndSupportsPartialAdminUpdate() {
        User admin = saveUser("setting_admin", "ADMIN");
        UserContext.set(admin.getId());

        AdminSettingService service = new AdminSettingService(
                settingRepository,
                userRepository
        );

        var defaults = service.getSettings();
        assertThat(defaults.signupBonusCredits()).isEqualTo(10000);
        assertThat(defaults.generationCostCredits()).isEqualTo(10);
        assertThat(defaults.signupEnabled()).isTrue();

        var updated = service.updateSettings(new SystemSettingRequest(
                null,
                3000,
                null,
                null,
                null,
                "系统维护公告",
                false,
                null,
                null,
                true,
                true
        ));

        assertThat(updated.signupBonusCredits()).isEqualTo(3000);
        assertThat(updated.generationCostCredits()).isEqualTo(10);
        assertThat(updated.announcement()).isEqualTo("系统维护公告");
        assertThat(updated.announcementEnabled()).isFalse();
        assertThat(updated.maintenanceMode()).isTrue();
        assertThat(updated.aiDebugLogEnabled()).isTrue();
    }

    @Test
    void rejectsNonAdminAndInvalidValues() {
        User user = saveUser("setting_user", "USER");
        User admin = saveUser("setting_admin_2", "ADMIN");
        AdminSettingService service = new AdminSettingService(
                settingRepository,
                userRepository
        );

        UserContext.set(user.getId());
        assertThatThrownBy(() -> service.updateSettings(new SystemSettingRequest(
                "新平台名",
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null
        )))
                .isInstanceOfSatisfying(BizException.class, error -> {
                    assertThat(error.getErrorCode())
                            .isEqualTo(ErrorCode.ADMIN_SETTING_FORBIDDEN);
                    assertThat(error.getHttpStatus()).isEqualTo(HttpStatus.FORBIDDEN);
                });

        UserContext.set(admin.getId());
        assertThatThrownBy(() -> service.updateSettings(new SystemSettingRequest(
                "",
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null
        )))
                .isInstanceOfSatisfying(BizException.class, error ->
                        assertThat(error.getErrorCode())
                                .isEqualTo(ErrorCode.ADMIN_SETTING_PARAMETER_INVALID));
    }

    @Test
    void registrationUsesConfiguredSwitchAndSignupBonus() {
        User admin = saveUser("setting_admin_3", "ADMIN");
        AdminSettingService settingService = new AdminSettingService(
                settingRepository,
                userRepository
        );
        UserContext.set(admin.getId());
        settingService.updateSettings(new SystemSettingRequest(
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                false,
                null,
                null,
                null
        ));

        TokenService tokenService = new TokenService();
        ReflectionTestUtils.setField(tokenService, "tokenTtlHours", 1L);
        AuthService authService = new AuthService(
                userRepository,
                passwordEncoder,
                tokenService,
                settingService
        );
        RegisterRequest request = new RegisterRequest(
                "new_setting_user",
                "test123",
                "新用户",
                "new@example.com"
        );

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOfSatisfying(BizException.class, error ->
                        assertThat(error.getMessage()).contains("注册暂未开放"));

        settingService.updateSettings(new SystemSettingRequest(
                null,
                4321,
                null,
                null,
                null,
                null,
                null,
                true,
                null,
                null,
                null
        ));
        var response = authService.register(request);

        assertThat(response.user().credits()).isEqualTo(4321);
    }

    private User saveUser(String username, String role) {
        return userRepository.save(User.builder()
                .username(username)
                .password(passwordEncoder.encode("test123"))
                .nickname(username)
                .role(role)
                .credits(100)
                .status(1)
                .deleted(false)
                .build());
    }
}
