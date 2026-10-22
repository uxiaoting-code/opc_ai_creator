package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 智能体节点，对应 {@code t_agent_node}。
 *
 * <p>节点不区分「内置 / 模型 / MCP / 知识库」四种类型，
 * 统一用 {@code toolSource + toolRefId + toolKey} 三件套定位。
 */
@Entity
@Table(name = "t_agent_node")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AgentNode extends BaseEntity {

    @Column(name = "agent_id", nullable = false)
    private Long agentId;

    /** 编排内唯一，如 n1 */
    @Column(name = "node_key", nullable = false, length = 50)
    private String nodeKey;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    /** MODEL / KNOWLEDGE / MCP / BUILTIN */
    @Column(name = "tool_source", nullable = false, length = 20)
    private String toolSource;

    @Column(name = "tool_ref_id")
    private Long toolRefId;

    @Column(name = "tool_key", nullable = false, length = 100)
    private String toolKey;

    /** 引用时的名称快照，防原对象被删后显示不出来 */
    @Column(name = "tool_name_snapshot", length = 100)
    private String toolNameSnapshot;

    @Column(name = "params_json", length = 4000)
    private String paramsJson;

    @Column(name = "enabled", nullable = false)
    @Builder.Default
    private Boolean enabled = true;

    @Column(name = "order_index", nullable = false)
    @Builder.Default
    private Integer orderIndex = 0;

    /** 条件路由：命中这些关键词（逗号分隔）时改走目标节点 */
    @Column(name = "route_keywords", length = 255)
    private String routeKeywords;

    @Column(name = "route_target_key", length = 50)
    private String routeTargetKey;
}
