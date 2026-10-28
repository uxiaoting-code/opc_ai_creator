package com.opc.server.dto;

/**
 * 新密码只在本次重置响应中返回一次。
 */
public record AdminResetPasswordResponse(
        Long userId,
        String username,
        String newPassword
) {
}
