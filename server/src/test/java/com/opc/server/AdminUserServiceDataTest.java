package com.opc.server;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.AdminUserCreditsRequest;
import com.opc.server.dto.AdminUserStatusRequest;
import com.opc.server.entity.User;
import com.opc.server.repository.CallLogRepository;
import com.opc.server.repository.CreditTransactionRepository;
import com.opc.server.repository.UserRepository;
import com.opc.server.security.PasswordEncoder;
import com.opc.server.security.TokenService;
import com.opc.server.security.UserContext;
import com.opc.server.service.AdminUserService;
import com.opc.server.service.CreditTransactionService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
class AdminUserServiceDataTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CreditTransactionRepository creditTransactionRepository;

    @Autowired
    private CallLogRepository callLogRepository;

    private final PasswordEncoder passwordEncoder = new PasswordEncoder();

    @AfterEach
    void clearUserContext() {
        UserContext.clear();
    }

    @Test
    void listsAdjustsFreezesAndResetsUser() {
        User admin = userRepository.save(User.builder()
                .username("admin_test")
                .password(passwordEncoder.encode("admin123"))
                .nickname("管理员")
                .role("ADMIN")
                .credits(100)
                .status(1)
                .deleted(false)
                .build());
        User user = userRepository.save(User.builder()
                .username("demo_test")
                .password(passwordEncoder.encode("demo123"))
                .nickname("测试用户")
                .email("demo@example.com")
                .role("USER")
                .credits(100)
                .status(1)
                .deleted(false)
                .build());

        TokenService tokenService = new TokenService();
        ReflectionTestUtils.setField(tokenService, "tokenTtlHours", 1L);
        CreditTransactionService creditTransactionService = new CreditTransactionService(
                creditTransactionRepository,
                userRepository,
                callLogRepository
        );
        AdminUserService service = new AdminUserService(
                userRepository,
                passwordEncoder,
                tokenService,
                creditTransactionService
        );

        UserContext.set(user.getId());
        assertThatThrownBy(() -> service.listUsers(null, null, 1, 10))
                .isInstanceOfSatisfying(BizException.class, error -> {
                    assertThat(error.getErrorCode())
                            .isEqualTo(ErrorCode.ADMIN_USER_FORBIDDEN);
                    assertThat(error.getHttpStatus()).isEqualTo(HttpStatus.FORBIDDEN);
                });

        UserContext.set(admin.getId());
        var page = service.listUsers("demo@example.com", 1, 1, 10);
        assertThat(page.total()).isEqualTo(1);
        assertThat(page.list().getFirst().username()).isEqualTo("demo_test");

        var credited = service.adjustCredits(
                user.getId(),
                new AdminUserCreditsRequest(250)
        );
        assertThat(credited.credits()).isEqualTo(350);

        String freezeToken = tokenService.issue(user.getId(), user.getUsername());
        assertThat(tokenService.resolveUserId(freezeToken)).contains(user.getId());
        var frozen = service.updateStatus(
                user.getId(),
                new AdminUserStatusRequest(0)
        );
        assertThat(frozen.status()).isZero();
        assertThat(frozen.statusLabel()).isEqualTo("冻结");
        assertThat(tokenService.resolveUserId(freezeToken)).isEmpty();

        String resetToken = tokenService.issue(user.getId(), user.getUsername());
        assertThat(tokenService.resolveUserId(resetToken)).contains(user.getId());
        var reset = service.resetPassword(user.getId(), "NewPass123");
        assertThat(reset.newPassword()).isEqualTo("NewPass123");
        assertThat(tokenService.resolveUserId(resetToken)).isEmpty();
        User reloaded = userRepository.findById(user.getId()).orElseThrow();
        assertThat(passwordEncoder.matches("NewPass123", reloaded.getPassword())).isTrue();
    }
}
