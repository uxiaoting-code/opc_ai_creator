package com.opc.server.repository;

import com.opc.server.entity.MarketOrder;
import com.opc.server.entity.enums.MediaType;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface MarketOrderRepository extends JpaRepository<MarketOrder, Long> {

    Optional<MarketOrder> findByOrderNo(String orderNo);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from MarketOrder o where o.id = :id")
    Optional<MarketOrder> findByIdForUpdate(@Param("id") Long id);

    @Query("""
            select o from MarketOrder o
             where o.status = com.opc.server.entity.enums.MarketOrderStatus.OPEN
               and o.deadlineAt > :now
               and o.tasksTaken < o.tasksTotal
               and (:mediaType is null or o.mediaType = :mediaType)
               and not exists (
                   select 1 from OrderAcceptance a
                    where a.orderId = o.id and a.userId = :userId
               )
             order by o.deadlineAt asc, o.id desc
            """)
    Page<MarketOrder> findAvailable(
            @Param("userId") Long userId,
            @Param("mediaType") MediaType mediaType,
            @Param("now") LocalDateTime now,
            Pageable pageable);
}