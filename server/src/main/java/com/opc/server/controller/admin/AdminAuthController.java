package com.opc.server.controller.admin;

import com.opc.server.common.Result;
import com.opc.server.dto.AuthResponse;
import com.opc.server.dto.LoginRequest;
import com.opc.server.dto.UserResponse;
import com.opc.server.security.UserContext;
import com.opc.server.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 管理端认证接口。
 *
 * <p>与 C 端 {@code /api/auth} 完全隔离：
 * <ul>
 *   <li>{@code POST /api/admin/auth/login} —— 唯一在 {@code WebConfig} 里放行的管理端路径；</li>
 *   <li>{@code GET  /api/admin/auth/profile} —— 需要 ADMIN 令牌。</li>
 * </ul>
 *
 * <p>登录只发令牌，不做角色判断以外的任何业务；角色校验在
 * {@code AuthService.loginAdmin()} 与 {@code AuthInterceptor} 两处都做了：
 * 前者拦住「拿普通账号登录后台」，后者拦住「拿普通账号的令牌直接调管理接口」。
 */
@RestController
@RequestMapping("/api/admin/auth")
public class AdminAuthController {

    private final AuthService authService;

    public AdminAuthController(AuthService authService) {
        this.authService = authService;
    }

    /** 管理员登录。此接口在 WebConfig 里被排除在登录拦截之外。 */
    @PostMapping("/login")
    public Result<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return Result.success(authService.loginAdmin(request));
    }

    /** 当前管理员资料，用于后台顶部栏「超级管理员」与退出按钮。 */
    @GetMapping("/profile")
    public Result<UserResponse> profile() {
        return Result.success(authService.getProfile(UserContext.require()));
    }
}
