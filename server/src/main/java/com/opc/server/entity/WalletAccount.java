package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.persistence.Version;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** 用户现金钱包账户；算力余额仍保存在 User.credits。 */
@Entity
@Table(name = "t_wallet_account", uniqueConstraints = @UniqueConstraint(name = "uk_wallet_user", columnNames = "user_id"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WalletAccount extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "withdrawable_fen", nullable = false)
    @Builder.Default
    private Long withdrawableFen = 0L;

    @Column(name = "frozen_fen", nullable = false)
    @Builder.Default
    private Long frozenFen = 0L;

    @Column(name = "total_income_fen", nullable = false)
    @Builder.Default
    private Long totalIncomeFen = 0L;

    @Column(name = "total_withdrawn_fen", nullable = false)
    @Builder.Default
    private Long totalWithdrawnFen = 0L;

    @Version
    @Column(name = "version", nullable = false)
    @Builder.Default
    private Long version = 0L;

    public void addIncome(long amountFen) {
        withdrawableFen += amountFen;
        totalIncomeFen += amountFen;
    }

    public void freeze(long amountFen) {
        withdrawableFen -= amountFen;
        frozenFen += amountFen;
    }

    public void completeWithdrawal(long amountFen) {
        frozenFen -= amountFen;
        totalWithdrawnFen += amountFen;
    }

    public void refundWithdrawal(long amountFen) {
        frozenFen -= amountFen;
        withdrawableFen += amountFen;
    }
}