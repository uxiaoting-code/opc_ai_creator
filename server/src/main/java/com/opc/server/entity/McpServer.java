package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/** MCP 服务端，对应 {@code t_mcp_server}（需求 3.3）。 */
@Entity
@Table(name = "t_mcp_server")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class McpServer extends BaseEntity {

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    /** HTTP / SSE / STDIO */
    @Column(name = "transport", nullable = false, length = 20)
    @Builder.Default
    private String transport = "HTTP";

    @Column(name = "endpoint", length = 255)
    private String endpoint;

    /** STDIO 模式下启动命令 */
    @Column(name = "command", length = 500)
    private String command;

    @Column(name = "env_json", length = 2000)
    private String envJson;

    @Column(name = "auth_type", nullable = false, length = 20)
    @Builder.Default
    private String authType = "NONE";

    @Column(name = "api_key", length = 255)
    private String apiKey;

    /** ONLINE / OFFLINE */
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "OFFLINE";

    @Column(name = "last_discover_at")
    private LocalDateTime lastDiscoverAt;

    @Column(name = "tool_count", nullable = false)
    @Builder.Default
    private Integer toolCount = 0;

    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
