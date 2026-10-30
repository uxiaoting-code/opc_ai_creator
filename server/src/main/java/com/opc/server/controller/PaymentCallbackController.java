package com.opc.server.controller;

import com.opc.server.common.Result;
import com.opc.server.dto.PaymentCallbackRequest;
import com.opc.server.dto.RechargeOrderResponse;
import com.opc.server.service.WalletService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 支付渠道服务端回调，不使用用户 Bearer token，由渠道签名验真。 */
@RestController
@RequestMapping("/api/payments")
public class PaymentCallbackController {

    private final WalletService walletService;

    public PaymentCallbackController(WalletService walletService) {
        this.walletService = walletService;
    }

    @PostMapping("/callback/{channelCode}")
    public Result<RechargeOrderResponse> callback(
            @PathVariable String channelCode,
            @Valid @RequestBody PaymentCallbackRequest request) {
        return Result.success(
                walletService.paymentCallback(channelCode, request),
                "支付回调已处理");
    }
}