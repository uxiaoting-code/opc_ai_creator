package com.opc.server.repository;

import com.opc.server.entity.OrderAcceptance;
import com.opc.server.entity.enums.AcceptanceStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.Optional;

@Repository
public interface OrderAcceptanceRepository extends JpaRepository<OrderAcceptance, Long> {

    Optional<OrderAcceptance> findByOrderIdAndUserId(Long orderId, Long userId);

    boolean existsByOrderIdAndUserId(Long orderId, Long userId);

    boolean existsByUserIdAndStatusIn(Long userId, Collection<AcceptanceStatus> statuses);

    Page<OrderAcceptance> findByUserIdAndStatusOrderByCreatedAtDesc(
            Long userId, AcceptanceStatus status, Pageable pageable);

    Page<OrderAcceptance> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);
}