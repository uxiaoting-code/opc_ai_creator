package com.opc.server.dto;

import com.opc.server.entity.MarketOrder;
import com.opc.server.entity.Submission;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.entity.enums.ReviewStatus;

import java.time.LocalDateTime;

/** 作品提交/审核状态响应。 */
public record SubmissionResponse(
        Long id,
        String submissionNo,
        Long orderId,
        String orderTitle,
        Long acceptanceId,
        Long taskId,
        MediaType mediaType,
        String mediaTypeLabel,
        String title,
        String note,
        String resultUrl,
        String thumbnailUrl,
        Long durationMs,
        Integer versionNo,
        ReviewStatus status,
        String statusLabel,
        String reviewNote,
        LocalDateTime submittedAt,
        LocalDateTime reviewedAt,
        Long rewardFen
) {

    public static SubmissionResponse from(Submission submission, MarketOrder order) {
        return new SubmissionResponse(
                submission.getId(),
                submission.getSubmissionNo(),
                submission.getOrderId(),
                order == null ? null : order.getTitle(),
                submission.getAcceptanceId(),
                submission.getTaskId(),
                submission.getMediaType(),
                submission.getMediaType() == null ? null : submission.getMediaType().getLabel(),
                submission.getTitle(),
                submission.getNote(),
                submission.getResultUrl(),
                submission.getThumbnailUrl(),
                submission.getDurationMs(),
                submission.getVersionNo(),
                submission.getStatus(),
                submission.getStatus() == null ? null : submission.getStatus().getLabel(),
                submission.getReviewNote(),
                submission.getSubmittedAt(),
                submission.getReviewedAt(),
                order == null ? null : order.getRewardFen());
    }
}