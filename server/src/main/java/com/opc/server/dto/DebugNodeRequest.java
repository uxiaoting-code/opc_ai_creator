package com.opc.server.dto;

public record DebugNodeRequest(Long agentId, Long nodeId, String input) {
}
