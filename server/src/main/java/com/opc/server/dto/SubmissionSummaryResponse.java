package com.opc.server.dto;

import java.time.LocalDateTime;

/** M2 提交记录接入前的轻量摘要，M1 工作台固定返回 null。 */
public record SubmissionSummaryResponse(
        Long id,
        String status,
        String title,
        LocalDateTime submittedAt
) {
}