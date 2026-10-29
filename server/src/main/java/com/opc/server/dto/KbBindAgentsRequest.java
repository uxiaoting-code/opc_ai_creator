package com.opc.server.dto;

import java.util.List;

public record KbBindAgentsRequest(List<Long> agentIds) {
}
