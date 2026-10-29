package com.opc.server.dto;

public record ModelShareItem(
        String modelName,
        long calls,
        double percent
) {
}
