package com.opc.server.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 注册请求。 */
public record RegisterRequest(

        @NotBlank(message = "请输入账号")
        @Size(min = 4, max = 20, message = "账号长度需为 4-20 位")
        String username,

        @NotBlank(message = "请输入密码")
        @Size(min = 6, max = 64, message = "密码长度需为 6-64 位")
        String password,

        @Size(max = 50, message = "昵称最长 50 个字符")
        String nickname,

        @Email(message = "邮箱格式不正确")
        String email
) {
}
