package com.opc.server.dto;

import java.util.List;

public record KbSearchResponse(
        String query,
        long elapsedMs,
        List<Item> items
) {

    public record Item(
            Long chunkId,
            Long documentId,
            String documentName,
            String content,
            double score
    ) {
    }
}
