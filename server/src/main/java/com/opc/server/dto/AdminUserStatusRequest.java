package com.opc.server.dto;

/**
 * 1 正常，0 冻结。
 */
public record AdminUserStatusRequest(Integer status) {
}
