package com.opc.server.repository;

import com.opc.server.entity.WalletTransaction;
import com.opc.server.entity.enums.WalletTransactionType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface WalletTransactionRepository extends JpaRepository<WalletTransaction, Long> {

    @Query("""
            select t from WalletTransaction t
             where t.userId = :userId
               and (:type is null or t.type = :type)
             order by t.createdAt desc, t.id desc
            """)
    Page<WalletTransaction> findMy(
            @Param("userId") Long userId,
            @Param("type") WalletTransactionType type,
            Pageable pageable);

    boolean existsByTypeAndReferenceTypeAndReferenceId(
            WalletTransactionType type, String referenceType, Long referenceId);
}