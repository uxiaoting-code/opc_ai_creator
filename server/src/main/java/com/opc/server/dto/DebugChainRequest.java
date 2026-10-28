package com.opc.server.dto;

public record DebugChainRequest(Long agentId, String input, Boolean saveLog) {
}
