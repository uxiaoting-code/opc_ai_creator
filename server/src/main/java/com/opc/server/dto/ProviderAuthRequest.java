package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;

public record ProviderAuthRequest(
        @NotBlank(message = "请选择鉴权方式") String authType,
        String apiKey,
        String headerName,
        String headerValue,
        String oauthTokenUrl,
        String oauthClientId,
        String oauthClientSecret
) {
}
