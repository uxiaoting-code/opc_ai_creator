package com.opc.server.dto;

import java.util.Map;

public record McpInvokeRequest(Map<String, Object> params) {
}
