package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** 用户提交作品请求。resultUrl 由服务端从 task 读取，客户端不能伪造。 */
public record SubmissionCreateRequest(
        @NotNull Long orderId,
        @NotNull Long taskId,
        @NotBlank @Size(max = 120) String title,
        @Size(max = 1000) String note
) {
}