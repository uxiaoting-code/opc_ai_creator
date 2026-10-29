package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;

public record GatewayEndpointRequest(
        @NotBlank(message = "请填写接口名称") String name,
        String method,
        @NotBlank(message = "请填写接口路径") String path,
        Long agentId,
        Boolean authRequired,
        String rateLimit,
        Boolean online,
        String remark
) {
}
