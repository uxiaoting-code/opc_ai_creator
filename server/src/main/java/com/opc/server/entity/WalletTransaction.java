package com.opc.server.entity;

import com.opc.server.entity.enums.WalletTransactionType;
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

/** 现金钱包流水；amountFen 始终为正数，方向由 type 表示。 */
@Entity
@Table(
        name = "t_wallet_transaction",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_wallet_transaction_no", columnNames = "transaction_no"),
                @UniqueConstraint(name = "uk_wallet_reference", columnNames = {"type", "reference_type", "reference_id"})
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WalletTransaction extends BaseEntity {

    @Column(name = "transaction_no", nullable = false, length = 32)
    private String transactionNo;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 30)
    private WalletTransactionType type;

    @Column(name = "amount_fen", nullable = false)
    private Long amountFen;

    @Column(name = "balance_after_fen", nullable = false)
    private Long balanceAfterFen;

    @Column(name = "reference_type", length = 30)
    private String referenceType;

    @Column(name = "reference_id")
    private Long referenceId;

    @Column(name = "description", nullable = false, length = 255)
    private String description;
}