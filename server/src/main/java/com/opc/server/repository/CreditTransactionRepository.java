package com.opc.server.repository;

import com.opc.server.entity.CreditTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface CreditTransactionRepository
        extends JpaRepository<CreditTransaction, Long>,
                JpaSpecificationExecutor<CreditTransaction> {

    List<CreditTransaction> findByCreatedAtBetweenOrderByCreatedAtAsc(
            LocalDateTime start, LocalDateTime end);

    List<CreditTransaction> findAllByOrderByCreatedAtDesc();
}
