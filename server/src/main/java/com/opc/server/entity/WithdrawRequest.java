package com.opc.server.entity;

import com.opc.server.entity.enums.WithdrawStatus;
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

/** 用户提现申请。完整收款账号不落明文库，只存脱敏快照。 */
@Entity
@Table(name = "t_withdraw_request", uniqueConstraints = @UniqueConstraint(name = "uk_withdraw_no", columnNames = "withdraw_no"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WithdrawRequest extends BaseEntity {

    @Column(name = "withdraw_no", nullable = false, length = 32)
    private String withdrawNo;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "amount_fen", nullable = false)
    private Long amountFen;

    @Column(name = "channel_code", nullable = false, length = 30)
    private String channelCode;

    @Column(name = "account_name", nullable = false, length = 100)
    private String accountName;

    @Column(name = "account_no_masked", nullable = false, length = 100)
    private String accountNoMasked;

    @Column(name = "account_snapshot_json", columnDefinition = "TEXT")
    private String accountSnapshotJson;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private WithdrawStatus status = WithdrawStatus.PENDING;

    @Column(name = "failure_reason", length = 500)
    private String failureReason;

    @Column(name = "external_trade_no", length = 100)
    private String externalTradeNo;

    @Column(name = "processed_at")
    private LocalDateTime processedAt;
}