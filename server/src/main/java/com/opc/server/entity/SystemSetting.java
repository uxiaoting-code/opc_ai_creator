package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 系统运行参数，对应 {@code t_system_setting}。
 *
 * <p>该表固定只有一行，主键始终为 {@link #SINGLETON_ID}。使用专用列而不是
 * Key-Value 表，便于后端对数值范围做类型校验，也避免每次读取都要把字符串
 * 转成业务类型。
 */
@Entity
@Table(name = "t_system_setting")
@Getter
@Setter
@NoArgsConstructor
public class SystemSetting {

    public static final long SINGLETON_ID = 1L;

    @Id
    private Long id = SINGLETON_ID;

    @Column(name = "platform_name", nullable = false, length = 100)
    private String platformName = "星枢 AI 聚合平台";

    /** 新用户注册时默认赠送的算力。 */
    @Column(name = "signup_bonus_credits", nullable = false)
    private Integer signupBonusCredits = 10000;

    /** 一次生成任务的基础算力消耗。 */
    @Column(name = "generation_cost_credits", nullable = false)
    private Integer generationCostCredits = 10;

    @Column(name = "recharge_bonus_percent", nullable = false, precision = 10, scale = 2)
    private BigDecimal rechargeBonusPercent = new BigDecimal("5.00");

    @Column(name = "credit_price", nullable = false, precision = 10, scale = 2)
    private BigDecimal creditPrice = new BigDecimal("1.00");

    @Column(name = "announcement", nullable = false, length = 2000)
    private String announcement = "";

    @Column(name = "announcement_enabled", nullable = false)
    private Boolean announcementEnabled = true;

    @Column(name = "signup_enabled", nullable = false)
    private Boolean signupEnabled = true;

    /** 保留既有管理端契约字段；本轮页面不单独展示充值通道开关。 */
    @Column(name = "recharge_enabled", nullable = false)
    private Boolean rechargeEnabled = true;

    @Column(name = "maintenance_mode", nullable = false)
    private Boolean maintenanceMode = false;

    @Column(name = "ai_debug_log_enabled", nullable = false)
    private Boolean aiDebugLogEnabled = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public static SystemSetting defaults() {
        return new SystemSetting();
    }

    @PrePersist
    protected void onCreate() {
        if (id == null) {
            id = SINGLETON_ID;
        }
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
