package com.opc.server.dto;

public record TopUserItem(
        int rank,
        Long userId,
        String userName,
        long creditsUsed
) {
}
