package com.opc.server.dto;

/** 编排节点。 */
public record AgentNodeResponse(
        Long id,
        String nodeKey,
        String name,
        int orderIndex,
        boolean enabled,
        String toolSource,
        String toolSourceLabel,
        Long toolRefId,
        String toolKey,
        String toolKind,
        String toolKindLabel,
        String toolNameSnapshot,
        String paramsJson,
        String routeKeywords,
        String routeTargetKey
) {
}
