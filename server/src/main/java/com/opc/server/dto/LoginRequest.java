package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 登录请求，对应前端 {@code AuthProvider.login()}。 */
public record LoginRequest(

        @NotBlank(message = "请输入账号")
        @Size(min = 4, max = 20, message = "账号长度需为 4-20 位")
        String username,

        @NotBlank(message = "请输入密码")
        @Size(min = 6, message = "密码至少 6 位")
        String password
) {
}
