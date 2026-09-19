package com.opc.server.dto;

import com.opc.server.entity.User;

import java.time.LocalDateTime;

/**
 * 用户信息响应。
 *
 * <p>刻意不直接返回 {@link User} 实体：实体里有密码哈希，
 * 靠 {@code @JsonIgnore} 挡是「防呆」而不是「设计」——
 * 一旦哪天有人给字段加了个 getter 或改了注解，密码就泄露了。
 * 显式 DTO 从源头上就不包含密码字段。
 */
public record UserResponse(
        Long id,
        String username,
        String nickname,
        String avatar,
        String email,
        String phone,
        String role,
        Integer credits,
        LocalDateTime createdAt
) {

    public static UserResponse from(User user) {
        if (user == null) {
            return null;
        }
        return new UserResponse(
                user.getId(),
                user.getUsername(),
                user.getNickname(),
                user.getAvatar(),
                user.getEmail(),
                user.getPhone(),
                user.getRole(),
                user.getCredits(),
                user.getCreatedAt()
        );
    }
}
