package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/** 算力流水，对应 {@code t_credit_transaction}。 */
@Entity
@Table(name = "t_credit_transaction")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreditTransaction extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** RECHARGE / CONSUME / REFUND / GIFT / ADMIN_ADJUST */
    @Column(name = "type", nullable = false, length = 20)
    private String type;

    /** 正数增加、负数减少 */
    @Column(name = "amount", nullable = false)
    private Integer amount;

    @Column(name = "balance_after", nullable = false)
    private Integer balanceAfter;

    @Column(name = "money_amount", precision = 10, scale = 2)
    private BigDecimal moneyAmount;

    @Column(name = "order_no", length = 40)
    private String orderNo;

    @Column(name = "channel", length = 30)
    private String channel;

    /** SUCCESS / PENDING / FAILED */
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "SUCCESS";

    @Column(name = "remark", length = 255)
    private String remark;

    @Column(name = "ref_task_id")
    private Long refTaskId;
}
