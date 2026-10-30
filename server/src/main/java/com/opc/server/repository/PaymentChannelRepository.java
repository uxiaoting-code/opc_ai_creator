package com.opc.server.repository;

import com.opc.server.entity.PaymentChannel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentChannelRepository extends JpaRepository<PaymentChannel, Long> {

    Optional<PaymentChannel> findByCode(String code);

    List<PaymentChannel> findByEnabledTrueOrderBySortOrderAsc();
}