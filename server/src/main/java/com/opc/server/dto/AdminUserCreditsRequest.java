package com.opc.server.dto;

/**
 * 后台调整用户算力。
 */
public record AdminUserCreditsRequest(
        Integer delta
) {
}
