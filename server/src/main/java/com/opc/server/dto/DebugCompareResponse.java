package com.opc.server.dto;

/** 版本对比：两个版本的模拟执行轨迹 + 一句差异摘要。 */
public record DebugCompareResponse(
        Integer versionA,
        Integer versionB,
        AgentPreviewResponse traceA,
        AgentPreviewResponse traceB,
        String summary
) {
}
