package com.opc.server.controller;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.PaymentChannelResponse;
import com.opc.server.dto.RechargeCreateRequest;
import com.opc.server.dto.RechargeOrderResponse;
import com.opc.server.dto.WalletSummaryResponse;
import com.opc.server.dto.WalletTransactionResponse;
import com.opc.server.dto.WithdrawCreateRequest;
import com.opc.server.dto.WithdrawRequestResponse;
import com.opc.server.entity.enums.PaymentChannelDirection;
import com.opc.server.entity.enums.WalletTransactionType;
import com.opc.server.security.UserContext;
import com.opc.server.service.WalletService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 用户端钱包、充值、提现接口（M3）。 */
@RestController
@RequestMapping("/api/wallet")
public class WalletController {

    private final WalletService walletService;

    public WalletController(WalletService walletService) {
        this.walletService = walletService;
    }

    @GetMapping("/summary")
    public Result<WalletSummaryResponse> summary() {
        return Result.success(walletService.summary(UserContext.require()));
    }

    @GetMapping("/transactions")
    public Result<PageResult<WalletTransactionResponse>> transactions(
            @RequestParam(required = false) WalletTransactionType type,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {
        return Result.success(walletService.listTransactions(
                UserContext.require(), type, page, pageSize));
    }

    @GetMapping("/recharge/channels")
    public Result<List<PaymentChannelResponse>> rechargeChannels() {
        return Result.success(walletService.listChannels(PaymentChannelDirection.RECHARGE));
    }

    @PostMapping("/recharges")
    public Result<RechargeOrderResponse> createRecharge(
            @Valid @RequestBody RechargeCreateRequest request) {
        return Result.success(
                walletService.createRecharge(UserContext.require(), request),
                "充值订单已创建");
    }

    @GetMapping("/recharges/{id}")
    public Result<RechargeOrderResponse> recharge(@PathVariable Long id) {
        return Result.success(walletService.getRecharge(UserContext.require(), id));
    }

    @GetMapping("/withdraw/channels")
    public Result<List<PaymentChannelResponse>> withdrawChannels() {
        return Result.success(walletService.listChannels(PaymentChannelDirection.WITHDRAW));
    }

    @PostMapping("/withdrawals")
    public Result<WithdrawRequestResponse> createWithdrawal(
            @Valid @RequestBody WithdrawCreateRequest request) {
        return Result.success(
                walletService.createWithdrawal(UserContext.require(), request),
                "提现申请已提交");
    }

    @GetMapping("/withdrawals/{id}")
    public Result<WithdrawRequestResponse> withdrawal(@PathVariable Long id) {
        return Result.success(walletService.getWithdrawal(UserContext.require(), id));
    }
}