package com.opc.server.controller;

import com.opc.server.common.Result;
import com.opc.server.dto.AuthResponse;
import com.opc.server.dto.LoginRequest;
import com.opc.server.dto.RegisterRequest;
import com.opc.server.dto.UserResponse;
import com.opc.server.security.UserContext;
import com.opc.server.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 认证接口。
 *
 * <p>路径与前端 {@code ApiEndpoints} 完全对应：
 * {@code /api/auth/login}、{@code /api/auth/register} 等。
 *
 * <p>注意这里没有用 {@code server.servlet.context-path=/api}：
 * 因为前端的静态资源地址是 {@code host} 而不是 {@code host/api}，
 * 一旦设了 context-path，{@code /upload/**} 也会被挪到 {@code /api/upload/**}，
 * 与前端 {@code AppConfig.assetBaseUrl} 对不上。所以 path 写全在注解里。
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /** 登录。此接口在 WebConfig 里被排除在登录拦截之外。 */
    @PostMapping("/login")
    public Result<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return Result.success(authService.login(request));
    }

    /** 注册并直接返回 token，前端注册后无需再登录一次。 */
    @PostMapping("/register")
    public Result<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return Result.success(authService.register(request));
    }

    /** 退出登录。 */
    @PostMapping("/logout")
    public Result<Void> logout(HttpServletRequest request) {
        authService.logout(extractToken(request));
        return Result.success();
    }

    /** 当前用户资料。 */
    @GetMapping("/profile")
    public Result<UserResponse> profile() {
        return Result.success(authService.getProfile(UserContext.require()));
    }

    private String extractToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7).trim();
        }
        return null;
    }
}
