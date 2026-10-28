package com.opc.server.dto;

import com.opc.server.entity.User;

import java.time.LocalDateTime;

/**
 * 管理端用户列表/操作结果。
 */
public record AdminUserResponse(
        Long id,
        String username,
        String nickname,
        String email,
        String phone,
        String role,
        Integer credits,
        Integer status,
        String statusLabel,
        LocalDateTime lastActiveAt,
        LocalDateTime createdAt
) {
    public static AdminUserResponse from(User user) {
        int status = user.getStatus() == null ? 0 : user.getStatus();
        return new AdminUserResponse(
                user.getId(),
                user.getUsername(),
                user.getNickname(),
                user.getEmail(),
                user.getPhone(),
                user.getRole(),
                user.getCredits() == null ? 0 : user.getCredits(),
                status,
                status == 1 ? "正常" : "冻结",
                user.getLastActiveAt(),
                user.getCreatedAt()
        );
    }
}
