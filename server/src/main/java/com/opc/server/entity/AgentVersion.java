package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** 智能体版本快照，对应 {@code t_agent_version}。 */
@Entity
@Table(name = "t_agent_version")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AgentVersion extends BaseEntity {

    @Column(name = "agent_id", nullable = false)
    private Long agentId;

    @Column(name = "version_no", nullable = false)
    private Integer versionNo;

    @Column(name = "snapshot_json", nullable = false, columnDefinition = "TEXT")
    private String snapshotJson;

    @Column(name = "remark", length = 255)
    private String remark;

    @Column(name = "operator", length = 50)
    private String operator;
}
