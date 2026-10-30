package com.opc.server.entity;

import com.opc.server.entity.enums.MediaType;
import com.opc.server.entity.enums.ReviewStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/** 用户围绕接单作品向订单方提交的审核记录。 */
@Entity
@Table(
        name = "t_submission",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_submission_no", columnNames = "submission_no"),
                @UniqueConstraint(name = "uk_order_user_version", columnNames = {"order_id", "user_id", "version_no"})
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Submission extends BaseEntity {

    @Column(name = "submission_no", nullable = false, length = 32)
    private String submissionNo;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "acceptance_id", nullable = false)
    private Long acceptanceId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "task_id", nullable = false)
    private Long taskId;

    @Enumerated(EnumType.STRING)
    @Column(name = "media_type", nullable = false, length = 20)
    private MediaType mediaType;

    @Column(name = "title", nullable = false, length = 120)
    private String title;

    @Column(name = "note", length = 1000)
    private String note;

    @Column(name = "result_url", nullable = false, length = 500)
    private String resultUrl;

    @Column(name = "thumbnail_url", length = 500)
    private String thumbnailUrl;

    @Column(name = "duration_ms")
    private Long durationMs;

    @Column(name = "version_no", nullable = false)
    @Builder.Default
    private Integer versionNo = 1;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private ReviewStatus status = ReviewStatus.PENDING;

    @Column(name = "review_note", length = 1000)
    private String reviewNote;

    @Column(name = "submitted_at", nullable = false)
    private LocalDateTime submittedAt;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;
}