package com.opc.server.controller.admin;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.ProviderAuthRequest;
import com.opc.server.dto.ProviderCreateRequest;
import com.opc.server.dto.ProviderDetailResponse;
import com.opc.server.dto.ProviderPricingRequest;
import com.opc.server.dto.ProviderRequestTemplateRequest;
import com.opc.server.dto.ProviderResponse;
import com.opc.server.dto.ProviderResponseTemplateRequest;
import com.opc.server.dto.ProviderTestRequest;
import com.opc.server.dto.ProviderTestResponse;
import com.opc.server.service.AiProviderConfigService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 管理端「大模型配置」接口（需求 3.1）。
 *
 * <p>全部路径都在 {@code /api/admin/**} 下，由 {@code AuthInterceptor}
 * 统一校验 ADMIN 角色；本 Controller 不重复写鉴权代码。
 */
@RestController
@RequestMapping("/api/admin/providers")
public class AdminProviderController {

    private final AiProviderConfigService service;

    public AdminProviderController(AiProviderConfigService service) {
        this.service = service;
    }

    /** 列表：支持类型筛选 + 关键字搜索。 */
    @GetMapping
    public Result<PageResult<ProviderResponse>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String keyword) {
        return Result.success(service.list(page, pageSize, type, keyword));
    }

    /** 新增模型（需求 3.1 第 1 步）。 */
    @PostMapping
    public Result<ProviderResponse> create(@Valid @RequestBody ProviderCreateRequest request) {
        return Result.success(service.create(request));
    }

    /** 详情：基础信息 + 鉴权 + 请求/响应模板。 */
    @GetMapping("/{id}")
    public Result<ProviderDetailResponse> detail(@PathVariable Long id) {
        return Result.success(service.detail(id));
    }

    /** 修改基础信息。 */
    @PutMapping("/{id}")
    public Result<ProviderResponse> update(@PathVariable Long id,
                                           @Valid @RequestBody ProviderCreateRequest request) {
        return Result.success(service.update(id, request));
    }

    /** 需求 3.1 第 2 步：配置鉴权。 */
    @PutMapping("/{id}/auth")
    public Result<ProviderDetailResponse> updateAuth(@PathVariable Long id,
                                                     @Valid @RequestBody ProviderAuthRequest request) {
        return Result.success(service.updateAuth(id, request));
    }

    /** 需求 3.1 第 3 步：请求模板。 */
    @PutMapping("/{id}/request-template")
    public Result<ProviderDetailResponse> updateRequestTemplate(
            @PathVariable Long id,
            @RequestBody ProviderRequestTemplateRequest request) {
        return Result.success(service.updateRequestTemplate(id, request));
    }

    /** 需求 3.1 第 4 步：响应模板。 */
    @PutMapping("/{id}/response-template")
    public Result<ProviderDetailResponse> updateResponseTemplate(
            @PathVariable Long id,
            @RequestBody ProviderResponseTemplateRequest request) {
        return Result.success(service.updateResponseTemplate(id, request));
    }

    /** 需求 3.1 第 5 步：连通性测试。 */
    @PostMapping("/{id}/test")
    public Result<ProviderTestResponse> test(
            @PathVariable Long id,
            @RequestBody(required = false) ProviderTestRequest request) {
        return Result.success(service.test(id, request));
    }

    /** 调价。 */
    @PutMapping("/{id}/pricing")
    public Result<ProviderResponse> updatePricing(@PathVariable Long id,
                                                  @RequestBody ProviderPricingRequest request) {
        return Result.success(service.updatePricing(id, request));
    }

    @PutMapping("/{id}/online")
    public Result<ProviderResponse> online(@PathVariable Long id) {
        return Result.success(service.setOnline(id, true));
    }

    @PutMapping("/{id}/offline")
    public Result<ProviderResponse> offline(@PathVariable Long id) {
        return Result.success(service.setOnline(id, false));
    }

    /** 逻辑删除（契约之外的补充能力）。 */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return Result.success();
    }
}
