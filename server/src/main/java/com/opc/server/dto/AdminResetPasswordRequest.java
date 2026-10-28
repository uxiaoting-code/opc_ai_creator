package com.opc.server.dto;

/**
 * 留空时由后端生成随机密码。
 */
public record AdminResetPasswordRequest(String newPassword) {
}
