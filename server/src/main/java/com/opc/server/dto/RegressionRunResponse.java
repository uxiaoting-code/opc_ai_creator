package com.opc.server.dto;

import java.util.List;

public record RegressionRunResponse(
        int total,
        int passed,
        int failed,
        List<Result> results
) {

    public record Result(
            Long caseId,
            String name,
            String input,
            boolean passed,
            String expectedKeywords,
            String actualOutput,
            long elapsedMs
    ) {
    }
}
