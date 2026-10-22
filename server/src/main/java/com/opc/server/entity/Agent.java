package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/** 智能体，对应 {@code t_agent}（需求 3.5 工作台的上层对象）。 */
@Entity
@Table(name = "t_agent")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Agent extends BaseEntity {

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    /** 英文标识，用于 API 调用；全局唯一 */
    @Column(name = "code", nullable = false, length = 50, unique = true)
    private String code;

    @Column(name = "category", nullable = false, length = 30)
    @Builder.Default
    private String category = "OTHER";

    @Column(name = "description", length = 500)
    private String description;

    /** emoji 头像 */
    @Column(name = "icon", length = 20)
    private String icon;

    /** 绑定的模型，指向 t_ai_provider_config.id */
    @Column(name = "model_provider_id")
    private Long modelProviderId;

    @Column(name = "system_prompt", columnDefinition = "TEXT")
    private String systemPrompt;

    @Column(name = "greeting", length = 500)
    private String greeting;

    @Column(name = "base_cost", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal baseCost = BigDecimal.ZERO;

    @Column(name = "max_rounds", nullable = false)
    @Builder.Default
    private Integer maxRounds = 8;

    @Column(name = "timeout_seconds", nullable = false)
    @Builder.Default
    private Integer timeoutSeconds = 60;

    @Column(name = "daily_quota", nullable = false)
    @Builder.Default
    private Integer dailyQuota = 5000;

    @Column(name = "allow_user_skill", nullable = false)
    @Builder.Default
    private Boolean allowUserSkill = false;

    @Column(name = "log_full_conversation", nullable = false)
    @Builder.Default
    private Boolean logFullConversation = true;

    /** DRAFT / PUBLISHED / OFFLINE */
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "DRAFT";

    @Column(name = "current_version", nullable = false)
    @Builder.Default
    private Integer currentVersion = 1;

    /** 调用统计先留列，P3 调用日志上线后再由聚合任务刷新 */
    @Column(name = "today_calls", nullable = false)
    @Builder.Default
    private Integer todayCalls = 0;

    @Column(name = "avg_elapsed_ms")
    private Long avgElapsedMs;

    @Column(name = "success_rate", precision = 5, scale = 2)
    private BigDecimal successRate;

    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
