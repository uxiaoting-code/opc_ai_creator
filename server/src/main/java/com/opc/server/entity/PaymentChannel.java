package com.opc.server.entity;

import com.opc.server.entity.enums.PaymentChannelDirection;
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

/** 充值/提现渠道配置。 */
@Entity
@Table(name = "t_payment_channel", uniqueConstraints = @UniqueConstraint(name = "uk_channel_code", columnNames = "code"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentChannel extends BaseEntity {

    @Column(name = "code", nullable = false, length = 30)
    private String code;

    @Column(name = "name", nullable = false, length = 50)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "direction", nullable = false, length = 20)
    private PaymentChannelDirection direction;

    @Column(name = "icon", length = 50)
    private String icon;

    @Column(name = "enabled", nullable = false)
    @Builder.Default
    private Boolean enabled = true;

    @Column(name = "min_fen", nullable = false)
    @Builder.Default
    private Long minFen = 100L;

    @Column(name = "max_fen", nullable = false)
    @Builder.Default
    private Long maxFen = 500000L;

    @Column(name = "fee_rate_bps", nullable = false)
    @Builder.Default
    private Integer feeRateBps = 0;

    @Column(name = "config_json", columnDefinition = "TEXT")
    private String configJson;

    @Column(name = "sort_order", nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;
}