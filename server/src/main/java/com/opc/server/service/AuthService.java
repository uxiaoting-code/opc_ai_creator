package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.AuthResponse;
import com.opc.server.dto.LoginRequest;
import com.opc.server.dto.RegisterRequest;
import com.opc.server.dto.UserResponse;
import com.opc.server.entity.User;
import com.opc.server.repository.UserRepository;
import com.opc.server.security.PasswordEncoder;
import com.opc.server.security.TokenService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 认证服务：注册、登录、退出。
 */
@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    /** 新用户注册赠送的算力点。 */
    private static final int INITIAL_CREDITS = 200;

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       TokenService tokenService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenService = tokenService;
    }

    /**
     * 注册并直接登录。
     *
     * <p>注册成功就返回 token，省掉「注册完再登一次」的多余交互 ——
     * 前端 {@code AuthProvider.register()} 也是这个预期。
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String username = request.username().trim();

        if (userRepository.existsByUsernameAndDeletedFalse(username)) {
            throw new BizException(ErrorCode.USERNAME_EXISTS);
        }

        User user = User.builder()
                .username(username)
                .password(passwordEncoder.encode(request.password()))
                .nickname(request.nickname() == null || request.nickname().isBlank()
                        ? username : request.nickname().trim())
                .email(request.email())
                .role("USER")
                .credits(INITIAL_CREDITS)
                .status(1)
                .deleted(false)
                .build();

        User saved = userRepository.save(user);
        log.info("新用户注册 id={} username={}", saved.getId(), saved.getUsername());

        String token = tokenService.issue(saved.getId(), saved.getUsername());
        return AuthResponse.of(token, UserResponse.from(saved));
    }

    /**
     * 登录。
     *
     * <p><b>账号不存在和密码错误返回完全相同的提示</b>，这是有意为之：
     * 如果两种情况的提示不同，攻击者就能靠它枚举出系统里有哪些账号。
     */
    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String username = request.username().trim();

        User user = userRepository.findByUsernameAndDeletedFalse(username)
                .orElseThrow(() -> new BizException(ErrorCode.PASSWORD_ERROR,
                        "账号或密码错误"));

        if (user.getStatus() == null || user.getStatus() != 1) {
            throw new BizException(ErrorCode.ACCOUNT_DISABLED);
        }

        if (!passwordEncoder.matches(request.password(), user.getPassword())) {
            throw new BizException(ErrorCode.PASSWORD_ERROR, "账号或密码错误");
        }

        String token = tokenService.issue(user.getId(), user.getUsername());
        log.info("用户登录 id={} username={}", user.getId(), user.getUsername());

        return AuthResponse.of(token, UserResponse.from(user));
    }

    /** 退出登录：吊销令牌。 */
    public void logout(String token) {
        tokenService.revoke(token);
    }

    /** 查询当前登录用户资料。 */
    @Transactional(readOnly = true)
    public UserResponse getProfile(Long userId) {
        User user = userRepository.findByIdAndDeletedFalse(userId)
                .orElseThrow(() -> new BizException(ErrorCode.USER_NOT_FOUND));
        return UserResponse.from(user);
    }
}
