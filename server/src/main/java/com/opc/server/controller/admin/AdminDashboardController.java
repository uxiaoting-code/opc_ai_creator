package com.opc.server.controller.admin;

import com.opc.server.common.Result;
import com.opc.server.dto.BillResponse;
import com.opc.server.dto.ModelShareItem;
import com.opc.server.dto.OverviewResponse;
import com.opc.server.dto.TrendPoint;
import com.opc.server.service.CreditTransactionService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 管理端「数据概览」接口（原型 pg-dash）。 */
@RestController
@RequestMapping("/api/admin/dashboard")
public class AdminDashboardController {

    private final CreditTransactionService service;

    public AdminDashboardController(CreditTransactionService service) {
        this.service = service;
    }

    @GetMapping("/overview")
    public Result<OverviewResponse> overview() {
        return Result.success(service.overview());
    }

    @GetMapping("/revenue-trend")
    public Result<List<TrendPoint>> revenueTrend(
            @RequestParam(defaultValue = "14") int days) {
        return Result.success(service.revenueTrend(days));
    }

    @GetMapping("/model-share")
    public Result<List<ModelShareItem>> modelShare(
            @RequestParam(defaultValue = "today") String range) {
        return Result.success(service.modelShare(range));
    }

    @GetMapping("/recent-orders")
    public Result<List<BillResponse>> recentOrders(
            @RequestParam(defaultValue = "5") int limit) {
        return Result.success(service.recentOrders(limit));
    }
}
