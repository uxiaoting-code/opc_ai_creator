package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;

public record RegressionCaseRequest(
        Long agentId,
        @NotBlank(message = "请填写用例名称") String name,
        @NotBlank(message = "请填写测试输入") String input,
        String expectedKeywords,
        Boolean enabled
) {
}
