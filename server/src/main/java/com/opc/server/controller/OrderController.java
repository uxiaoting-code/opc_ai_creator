package com.opc.server.controller;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.AcceptOrderResponse;
import com.opc.server.dto.MarketOrderResponse;
import com.opc.server.dto.OrderAcceptanceResponse;
import com.opc.server.dto.OrderDetailResponse;
import com.opc.server.dto.WorkbenchContextResponse;
import com.opc.server.entity.enums.AcceptanceStatus;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.security.UserContext;
import com.opc.server.service.OrderService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** 用户端接单市场接口（M1）。 */
@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping("/available")
    public Result<PageResult<MarketOrderResponse>> available(
            @RequestParam(required = false) MediaType mediaType,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {
        return Result.success(orderService.listAvailable(
                UserContext.require(), mediaType, page, pageSize));
    }

    @GetMapping("/my")
    public Result<PageResult<OrderAcceptanceResponse>> myAcceptances(
            @RequestParam(required = false) AcceptanceStatus status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {
        return Result.success(orderService.listMyAcceptances(
                UserContext.require(), status, page, pageSize));
    }

    @GetMapping("/{id}")
    public Result<OrderDetailResponse> detail(@PathVariable Long id) {
        return Result.success(orderService.getDetail(UserContext.require(), id));
    }

    @PostMapping("/{id}/accept")
    public Result<AcceptOrderResponse> accept(@PathVariable Long id) {
        return Result.success(
                orderService.acceptOrder(UserContext.require(), id),
                "接单成功");
    }

    @GetMapping("/{id}/workbench")
    public Result<WorkbenchContextResponse> workbench(@PathVariable Long id) {
        return Result.success(orderService.getWorkbench(UserContext.require(), id));
    }
}