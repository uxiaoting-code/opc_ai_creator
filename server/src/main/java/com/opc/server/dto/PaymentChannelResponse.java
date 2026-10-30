package com.opc.server.dto;

import com.opc.server.entity.PaymentChannel;
import com.opc.server.entity.enums.PaymentChannelDirection;

/** 支付/提现渠道响应。 */
public record PaymentChannelResponse(
        String code,
        String name,
        PaymentChannelDirection direction,
        String icon,
        Boolean enabled,
        Long minFen,
        Long maxFen,
        Integer feeRateBps,
        Integer sortOrder
) {

    public static PaymentChannelResponse from(PaymentChannel channel) {
        return new PaymentChannelResponse(
                channel.getCode(),
                channel.getName(),
                channel.getDirection(),
                channel.getIcon(),
                channel.getEnabled(),
                channel.getMinFen(),
                channel.getMaxFen(),
                channel.getFeeRateBps(),
                channel.getSortOrder());
    }
}