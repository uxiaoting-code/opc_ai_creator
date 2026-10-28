package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** 回归测试用例，对应 {@code t_regression_case}。 */
@Entity
@Table(name = "t_regression_case")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegressionCase extends BaseEntity {

    @Column(name = "agent_id", nullable = false)
    private Long agentId;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "input", nullable = false, columnDefinition = "TEXT")
    private String input;

    /** 期望输出包含的关键词，逗号分隔；为空表示只校验执行成功 */
    @Column(name = "expected_keywords", length = 500)
    private String expectedKeywords;

    @Column(name = "enabled", nullable = false)
    @Builder.Default
    private Boolean enabled = true;

    @Column(name = "created_by", length = 50)
    private String createdBy;
}
