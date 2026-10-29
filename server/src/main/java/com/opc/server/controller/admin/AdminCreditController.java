package com.opc.server.controller.admin;

import com.opc.server.common.Result;
import com.opc.server.dto.CreditByModelItem;
import com.opc.server.dto.CreditStatsResponse;
import com.opc.server.dto.TopUserItem;
import com.opc.server.service.CreditTransactionService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 管理端「算力使用」接口（原型 pg-usage）。 */
@RestController
@RequestMapping("/api/admin/credits")
public class AdminCreditController {

    private final CreditTransactionService service;

    public AdminCreditController(CreditTransactionService service) {
        this.service = service;
    }

    @GetMapping("/stats")
    public Result<CreditStatsResponse> stats(
            @RequestParam(defaultValue = "today") String range) {
        return Result.success(service.stats(range));
    }

    @GetMapping("/by-model")
    public Result<List<CreditByModelItem>> byModel(
            @RequestParam(defaultValue = "today") String range) {
        return Result.success(service.byModel(range));
    }

    @GetMapping("/top-users")
    public Result<List<TopUserItem>> topUsers(
            @RequestParam(defaultValue = "8") int limit) {
        return Result.success(service.topUsers(limit));
    }
}
