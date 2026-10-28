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

/** MCP 工具，对应 {@code t_mcp_tool}。映射到平台工具库后供工作台引用。 */
@Entity
@Table(name = "t_mcp_tool")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class McpTool extends BaseEntity {

    @Column(name = "server_id", nullable = false)
    private Long serverId;

    @Column(name = "tool_name", nullable = false, length = 100)
    private String toolName;

    /** 平台内唯一标识：mcp_{serverId}_{toolName} */
    @Column(name = "tool_key", nullable = false, length = 120, unique = true)
    private String toolKey;

    @Column(name = "display_name", length = 100)
    private String displayName;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "input_schema", columnDefinition = "TEXT")
    private String inputSchema;

    @Column(name = "enabled", nullable = false)
    @Builder.Default
    private Boolean enabled = true;

    @Column(name = "last_invoked_at")
    private LocalDateTime lastInvokedAt;

    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
