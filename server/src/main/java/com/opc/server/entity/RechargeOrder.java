package com.opc.server.entity;

import com.opc.server.entity.enums.RechargeOrderStatus;
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

/** 算力充值订单。支付成功后才增加 User.credits。 */
@Entity
@Table(name = "t_recharge_order", uniqueConstraints = @UniqueConstraint(name = "uk_recharge_no", columnNames = "recharge_no"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RechargeOrder extends BaseEntity {

    @Column(name = "recharge_no", nullable = false, length = 32)
    private String rechargeNo;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "amount_fen", nullable = false)
    private Long amountFen;

    @Column(name = "credits", nullable = false)
    private Integer credits;

    @Column(name = "channel_code", nullable = false, length = 30)
    private String channelCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private RechargeOrderStatus status = RechargeOrderStatus.PENDING;

    @Column(name = "external_trade_no", length = 100)
    private String externalTradeNo;

    @Column(name = "pay_url", length = 500)
    private String payUrl;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;
}