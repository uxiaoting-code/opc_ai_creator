package com.opc.server.dto;

/**
 * 统一工具库条目。
 *
 * <p>形状一旦冻结，后续接 MCP / 知识库都不用改前端：
 * {@code toolSource + toolRefId + toolKey} 三件套定位唯一能力。
 */
public record AdminToolResponse(
        String toolSource,
        String toolSourceLabel,
        Long toolRefId,
        String toolKey,
        String toolKind,
        String toolKindLabel,
        String name,
        String description,
        boolean enabled
) {
}
