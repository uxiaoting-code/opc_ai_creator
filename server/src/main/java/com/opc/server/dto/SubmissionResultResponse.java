package com.opc.server.dto;

/** 作品详情：提交快照 + 生成任务结果。 */
public record SubmissionResultResponse(
        SubmissionResponse submission,
        TaskResponse task
) {
}