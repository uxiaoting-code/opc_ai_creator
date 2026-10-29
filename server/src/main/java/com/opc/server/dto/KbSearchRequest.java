package com.opc.server.dto;

public record KbSearchRequest(String query, Integer topK) {
}
