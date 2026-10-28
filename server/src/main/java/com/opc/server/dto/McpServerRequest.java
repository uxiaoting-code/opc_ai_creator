package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;

public record McpServerRequest(
        @NotBlank(message = "请填写 MCP 服务名称") String name,
        String transport,
        String endpoint,
        String command,
        String envJson,
        String authType,
        String apiKey
) {
}
