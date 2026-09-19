package com.opc.server.dto;

/**
 * 登录/注册成功的响应。
 *
 * <p>字段名要与前端 {@code AuthProvider.login()} 里读取的一致：
 * {@code result['token']} 和 {@code result['user']}。
 */
public record AuthResponse(
        String token,
        UserResponse user
) {
    public static AuthResponse of(String token, UserResponse user) {
        return new AuthResponse(token, user);
    }
}
