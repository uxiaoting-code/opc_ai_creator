package com.opc.server.entity;

import com.opc.server.entity.enums.AcceptanceStatus;
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

/** 用户接单记录；同一用户对同一订单最多一条。 */
@Entity
@Table(
        name = "t_order_acceptance",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_acceptance_no", columnNames = "acceptance_no"),
                @UniqueConstraint(name = "uk_order_user", columnNames = {"order_id", "user_id"})
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderAcceptance extends BaseEntity {

    @Column(name = "acceptance_no", nullable = false, length = 32)
    private String acceptanceNo;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private AcceptanceStatus status = AcceptanceStatus.ACCEPTED;

    @Column(name = "accepted_at", nullable = false)
    private LocalDateTime acceptedAt;

    @Column(name = "submitted_at")
    private LocalDateTime submittedAt;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;
}