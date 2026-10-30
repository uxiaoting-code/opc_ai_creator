package com.opc.server.controller.admin;

import com.opc.server.common.Result;
import com.opc.server.dto.WithdrawRequestResponse;
import com.opc.server.dto.WithdrawStatusRequest;
import com.opc.server.service.WalletService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 后台处理提现申请（M3）。 */
@RestController
@RequestMapping("/api/admin/withdrawals")
public class AdminWithdrawalController {

    private final WalletService walletService;

    public AdminWithdrawalController(WalletService walletService) {
        this.walletService = walletService;
    }

    @PutMapping("/{id}/status")
    public Result<WithdrawRequestResponse> updateStatus(
            @PathVariable Long id,
            @Valid @RequestBody WithdrawStatusRequest request) {
        return Result.success(
                walletService.updateWithdrawStatus(id, request),
                "提现状态已更新");
    }
}