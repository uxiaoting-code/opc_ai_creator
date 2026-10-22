package com.opc.server.dto;

import java.math.BigDecimal;

public record ProviderPricingRequest(
        BigDecimal inputPrice,
        BigDecimal outputPrice,
        String priceUnit
) {
}
