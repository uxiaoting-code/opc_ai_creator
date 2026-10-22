package com.opc.server.dto;

/** 需求 3.1 第 4 步：响应模板（字段提取规则）。 */
public record ProviderResponseTemplateRequest(
        String successPath,
        String resultUrlPath,
        String thumbPath,
        String errorPath,
        String taskIdPath
) {
}
