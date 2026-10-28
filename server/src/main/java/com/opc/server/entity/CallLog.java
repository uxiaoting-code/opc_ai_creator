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

/**
 * 管理端调试/预览调用日志，对应 {@code t_call_log}。
 *
 * <p>每次调试（单节点 / 全链路 / 对话式 / 回归）按节点落一条记录，
 * 供「调试面板 → 日志追踪」查询。
 */
@Entity
@Table(name = "t_call_log")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CallLog extends BaseEntity {

    @Column(name = "session_id", length = 64)
    private String sessionId;

    @Column(name = "agent_id")
    private Long agentId;

    @Column(name = "agent_name", length = 100)
    private String agentName;

    /** NODE / CHAIN / CHAT / REGRESSION */
    @Column(name = "mode", nullable = false, length = 20)
    private String mode;

    @Column(name = "node_id")
    private Long nodeId;

    @Column(name = "node_key", length = 50)
    private String nodeKey;

    @Column(name = "node_name", length = 100)
    private String nodeName;

    @Column(name = "tool_kind", length = 30)
    private String toolKind;

    @Column(name = "input", columnDefinition = "TEXT")
    private String input;

    @Column(name = "output", columnDefinition = "TEXT")
    private String output;

    @Column(name = "success", nullable = false)
    @Builder.Default
    private Boolean success = true;

    @Column(name = "elapsed_ms")
    private Long elapsedMs;

    @Column(name = "credits", precision = 10, scale = 2)
    private BigDecimal credits;

    @Column(name = "error_msg", length = 1000)
    private String errorMsg;

    @Column(name = "operator", length = 50)
    private String operator;
}
