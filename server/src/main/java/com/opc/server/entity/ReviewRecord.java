package com.opc.server.entity;

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

/** 后台对 submission 的一次终态审核记录。 */
@Entity
@Table(
        name = "t_review_record",
        uniqueConstraints = @UniqueConstraint(name = "uk_review_submission", columnNames = "submission_id"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewRecord extends BaseEntity {

    @Column(name = "submission_id", nullable = false)
    private Long submissionId;

    @Column(name = "reviewer_id")
    private Long reviewerId;

    @Enumerated(EnumType.STRING)
    @Column(name = "decision", nullable = false, length = 20)
    private ReviewStatus decision;

    @Column(name = "comment", length = 1000)
    private String comment;
}