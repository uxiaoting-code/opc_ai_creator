package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** 对外网关接口定义，对应 {@code t_gateway_endpoint}。 */
@Entity
@Table(name = "t_gateway_endpoint")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GatewayEndpoint extends BaseEntity {

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "method", nullable = false, length = 10)
    @Builder.Default
    private String method = "POST";

    @Column(name = "path", nullable = false, length = 200)
    private String path;

    @Column(name = "agent_id")
    private Long agentId;

    @Column(name = "auth_required", nullable = false)
    @Builder.Default
    private Boolean authRequired = true;

    @Column(name = "rate_limit", length = 50)
    private String rateLimit;

    @Column(name = "online", nullable = false)
    @Builder.Default
    private Boolean online = true;

    @Column(name = "call_count", nullable = false)
    @Builder.Default
    private Long callCount = 0L;

    @Column(name = "remark", length = 500)
    private String remark;

    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
