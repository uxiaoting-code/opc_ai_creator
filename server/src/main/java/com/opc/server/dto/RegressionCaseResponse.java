package com.opc.server.dto;

import com.opc.server.entity.RegressionCase;

import java.time.LocalDateTime;

public record RegressionCaseResponse(
        Long id,
        Long agentId,
        String name,
        String input,
        String expectedKeywords,
        boolean enabled,
        String createdBy,
        LocalDateTime createdAt
) {

    public static RegressionCaseResponse from(RegressionCase c) {
        return new RegressionCaseResponse(
                c.getId(), c.getAgentId(), c.getName(), c.getInput(),
                c.getExpectedKeywords(), Boolean.TRUE.equals(c.getEnabled()),
                c.getCreatedBy(), c.getCreatedAt()
        );
    }
}
