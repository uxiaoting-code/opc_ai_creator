package com.opc.server.dto;

public record DebugChatRequest(Long agentId, String message, String sessionId) {
}
