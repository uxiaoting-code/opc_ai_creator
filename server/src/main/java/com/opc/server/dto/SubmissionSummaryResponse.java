package com.opc.server.dto;

import com.opc.server.entity.Submission;

import java.time.LocalDateTime;

/** 工作台最近一次提交的轻量摘要。 */
public record SubmissionSummaryResponse(
        Long id,
        String status,
        String title,
        LocalDateTime submittedAt
) {

    public static SubmissionSummaryResponse from(Submission submission) {
        return new SubmissionSummaryResponse(
                submission.getId(),
                submission.getStatus() == null ? null : submission.getStatus().name(),
                submission.getTitle(),
                submission.getSubmittedAt());
    }
}