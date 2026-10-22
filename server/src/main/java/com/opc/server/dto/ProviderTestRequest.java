package com.opc.server.dto;

/** 连通性测试入参；prompt 为空时用内置测试提示词。 */
public record ProviderTestRequest(String prompt) {
}
