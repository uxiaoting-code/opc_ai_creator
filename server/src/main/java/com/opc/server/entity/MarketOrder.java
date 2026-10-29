package com.opc.server.entity;

import com.opc.server.entity.enums.MarketOrderStatus;
import com.opc.server.entity.enums.MediaType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.persistence.Version;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/** 接单市场中的公开订单。 */
@Entity
@Table(
        name = "t_market_order",
        uniqueConstraints = @UniqueConstraint(name = "uk_market_order_no", columnNames = "order_no"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MarketOrder extends BaseEntity {

    @Column(name = "order_no", nullable = false, length = 32)
    private String orderNo;

    @Column(name = "title", nullable = false, length = 120)
    private String title;

    @Column(name = "brand_name", nullable = false, length = 100)
    private String brandName;

    @Lob
    @Column(name = "description", nullable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "media_type", nullable = false, length = 20)
    private MediaType mediaType;

    @Column(name = "reward_fen", nullable = false)
    private Long rewardFen;

    @Column(name = "credit_cost", nullable = false)
    @Builder.Default
    private Integer creditCost = 0;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "requirements_json", columnDefinition = "json")
    @Builder.Default
    private List<String> requirements = new ArrayList<>();

    @Column(name = "deadline_at", nullable = false)
    private LocalDateTime deadlineAt;

    @Column(name = "tasks_total", nullable = false)
    @Builder.Default
    private Integer tasksTotal = 0;

    @Column(name = "tasks_taken", nullable = false)
    @Builder.Default
    private Integer tasksTaken = 0;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private MarketOrderStatus status = MarketOrderStatus.OPEN;

    @Version
    @Column(name = "version", nullable = false)
    @Builder.Default
    private Long version = 0L;

    public boolean isExpired(LocalDateTime now) {
        return deadlineAt == null || !deadlineAt.isAfter(now);
    }

    public boolean isFull() {
        return tasksTaken != null && tasksTotal != null && tasksTaken >= tasksTotal;
    }

    public boolean isAcceptable(LocalDateTime now) {
        return status == MarketOrderStatus.OPEN && !isExpired(now) && !isFull();
    }

    public void takeOneSlot() {
        int current = tasksTaken == null ? 0 : tasksTaken;
        int total = tasksTotal == null ? 0 : tasksTotal;
        tasksTaken = current + 1;
        if (tasksTaken >= total) {
            status = MarketOrderStatus.COMPLETED;
        }
    }
}