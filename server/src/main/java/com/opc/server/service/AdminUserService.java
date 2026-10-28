package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.AdminResetPasswordResponse;
import com.opc.server.dto.AdminUserCreditsRequest;
import com.opc.server.dto.AdminUserResponse;
import com.opc.server.dto.AdminUserStatusRequest;
import com.opc.server.entity.User;
import com.opc.server.repository.UserRepository;
import com.opc.server.security.PasswordEncoder;
import com.opc.server.security.TokenService;
import com.opc.server.security.UserContext;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.Locale;

/**
 * 管理端用户服务。
 */
@Service
public class AdminUserService {

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 100;
    private static final int MAX_PASSWORD_LENGTH = 50;
    private static final String PASSWORD_CHARS =
            "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;
    private final SecureRandom random = new SecureRandom();

    public AdminUserService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            TokenService tokenService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenService = tokenService;
    }

    @Transactional(readOnly = true)
    public PageResult<AdminUserResponse> listUsers(
            String keyword,
            Integer status,
            int page,
            int pageSize) {
        requireAdmin();
        if (status != null && status != 0 && status != 1) {
            throw new BizException(ErrorCode.ADMIN_USER_STATUS_INVALID);
        }
        int safePage = Math.max(1, page);
        int safeSize = pageSize <= 0
                ? DEFAULT_PAGE_SIZE
                : Math.min(pageSize, MAX_PAGE_SIZE);
        var result = userRepository.searchAdminUsers(
                normalize(keyword),
                status,
                PageRequest.of(safePage - 1, safeSize)
        );
        return PageResult.from(result, AdminUserResponse::from);
    }

    @Transactional
    public AdminUserResponse adjustCredits(
            Long userId,
            AdminUserCreditsRequest request) {
        requireAdmin();
        if (request == null || request.delta() == null || request.delta() == 0) {
            throw new BizException(
                    ErrorCode.ADMIN_USER_CREDITS_INVALID,
                    "算力调整值不能为空或 0"
            );
        }
        User user = requireUser(userId);
        long current = user.getCredits() == null ? 0L : user.getCredits();
        long next = current + request.delta();
        if (next < 0 || next > Integer.MAX_VALUE) {
            throw new BizException(
                    ErrorCode.ADMIN_USER_CREDITS_INVALID,
                    "调整后的算力余额不合法"
            );
        }
        user.setCredits((int) next);
        return AdminUserResponse.from(userRepository.save(user));
    }

    @Transactional
    public AdminUserResponse updateStatus(
            Long userId,
            AdminUserStatusRequest request) {
        requireAdmin();
        Integer status = request == null ? null : request.status();
        if (status == null || (status != 0 && status != 1)) {
            throw new BizException(ErrorCode.ADMIN_USER_STATUS_INVALID);
        }
        User user = requireUser(userId);
        user.setStatus(status);
        User saved = userRepository.save(user);
        if (status == 0) {
            tokenService.revokeAllOf(userId);
        }
        return AdminUserResponse.from(saved);
    }

    @Transactional
    public AdminResetPasswordResponse resetPassword(
            Long userId,
            String requestedPassword) {
        requireAdmin();
        User user = requireUser(userId);
        String rawPassword = normalizePassword(requestedPassword);
        if (rawPassword == null) {
            rawPassword = generatePassword(10);
        } else if (rawPassword.length() < 6
                || rawPassword.length() > MAX_PASSWORD_LENGTH) {
            throw new BizException(
                    ErrorCode.ADMIN_USER_PASSWORD_INVALID,
                    "密码长度必须为 6-50 个字符"
            );
        }
        user.setPassword(passwordEncoder.encode(rawPassword));
        userRepository.save(user);
        tokenService.revokeAllOf(userId);
        return new AdminResetPasswordResponse(
                user.getId(),
                user.getUsername(),
                rawPassword
        );
    }

    private User requireAdmin() {
        Long userId = UserContext.require();
        User user = userRepository.findByIdAndDeletedFalse(userId)
                .orElseThrow(() -> new BizException(ErrorCode.ADMIN_USER_FORBIDDEN));
        if (!"ADMIN".equalsIgnoreCase(user.getRole())) {
            throw BizException.forbidden(ErrorCode.ADMIN_USER_FORBIDDEN);
        }
        return user;
    }

    private User requireUser(Long userId) {
        if (userId == null) {
            throw new BizException(ErrorCode.ADMIN_USER_PARAMETER_INVALID);
        }
        return userRepository.findByIdAndDeletedFalse(userId)
                .orElseThrow(() -> new BizException(ErrorCode.ADMIN_USER_NOT_FOUND));
    }

    private String generatePassword(int length) {
        StringBuilder password = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            password.append(PASSWORD_CHARS.charAt(random.nextInt(PASSWORD_CHARS.length())));
        }
        return password.toString();
    }

    private static String normalize(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim().toLowerCase(Locale.ROOT);
    }

    private static String normalizePassword(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
