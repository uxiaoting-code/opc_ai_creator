package com.opc.server.dto;

/**
 * 用户保存自定义 Prompt 的请求。
 *
 * <p>字段长度和必填校验放在 Service 层，项目统一以 6500 段业务错误码返回，
 * 避免与通用 Bean Validation 的 400 参数错误混用。
 */
public record PromptCreateRequest(
        String title,
        String content,
        String negativeContent,
        String category,
        String tags,
        String coverUrl
) {
}
