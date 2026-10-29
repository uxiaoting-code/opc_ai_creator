package com.opc.server.controller.admin;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.BillResponse;
import com.opc.server.dto.BillSummaryResponse;
import com.opc.server.dto.RechargeRequest;
import com.opc.server.service.CreditTransactionService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.Map;
import java.util.stream.Collectors;

/** 管理端「账单管理」接口（原型 pg-bills）。 */
@RestController
@RequestMapping("/api/admin/bills")
public class AdminBillController {

    private final CreditTransactionService service;

    public AdminBillController(CreditTransactionService service) {
        this.service = service;
    }

    @GetMapping
    public Result<PageResult<BillResponse>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) String type,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) String keyword) {
        return Result.success(service.bills(page, pageSize, type, startDate, endDate, keyword));
    }

    @GetMapping("/summary")
    public Result<BillSummaryResponse> summary(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return Result.success(service.summary(date));
    }

    @PostMapping("/recharge")
    public Result<BillResponse> recharge(@RequestBody RechargeRequest request) {
        return Result.success(service.recharge(request));
    }

    @PostMapping("/{id}/refund")
    public Result<BillResponse> refund(@PathVariable Long id,
                                       @RequestBody(required = false) Map<String, String> body) {
        String remark = body == null ? null : body.get("remark");
        return Result.success(service.refund(id, remark));
    }

    /** CSV 导出；前端点击「导出对账单」直接下载。 */
    @GetMapping("/export")
    public ResponseEntity<byte[]> export(
            @RequestParam(required = false) String type,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        var page = service.bills(1, 100, type, startDate, endDate, null);
        String csv = "订单号,用户,类型,金额,算力变动,渠道,状态,时间\n"
                + page.list().stream()
                .map(b -> String.join(",",
                        safe(b.orderNo()), safe(b.userName()), safe(b.typeLabel()),
                        b.amount() == null ? "" : b.amount().toPlainString(),
                        String.valueOf(b.creditsDelta()), safe(b.channel()),
                        safe(b.statusLabel()),
                        b.createdAt() == null ? "" : b.createdAt().toString()))
                .collect(Collectors.joining("\n"));
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=bills.csv")
                .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8))
                .body(csv.getBytes(StandardCharsets.UTF_8));
    }

    private static String safe(String value) {
        return value == null ? "" : value.replace(",", " ");
    }
}
