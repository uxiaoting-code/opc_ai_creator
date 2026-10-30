package com.opc.server.repository;

import com.opc.server.entity.RechargeOrder;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RechargeOrderRepository extends JpaRepository<RechargeOrder, Long> {

    Optional<RechargeOrder> findByIdAndUserId(Long id, Long userId);

    Optional<RechargeOrder> findByRechargeNo(String rechargeNo);

    Optional<RechargeOrder> findByExternalTradeNo(String externalTradeNo);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from RechargeOrder r where r.rechargeNo = :rechargeNo")
    Optional<RechargeOrder> findByRechargeNoForUpdate(@Param("rechargeNo") String rechargeNo);
}