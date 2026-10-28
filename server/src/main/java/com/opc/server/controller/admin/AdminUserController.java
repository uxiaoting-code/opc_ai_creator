package com.opc.server.controller.admin;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.AdminResetPasswordRequest;
import com.opc.server.dto.AdminResetPasswordResponse;
import com.opc.server.dto.AdminUserCreditsRequest;
import com.opc.server.dto.AdminUserResponse;
import com.opc.server.dto.AdminUserStatusRequest;
import com.opc.server.service.AdminUserService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 管理端用户管理接口。ADMIN 权限由 AuthInterceptor 统一校验，
 * Service 内再做一次角色校验作为纵深防御。
 */
@RestController
@RequestMapping("/api/admin/users")
public class AdminUserController {

    private final AdminUserService adminUserService;

    public AdminUserController(AdminUserService adminUserService) {
        this.adminUserService = adminUserService;
    }

    @GetMapping
    public Result<PageResult<AdminUserResponse>> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {
        return Result.success(
                adminUserService.listUsers(keyword, status, page, pageSize)
        );
    }

    @PostMapping("/{id}/credits")
    public Result<AdminUserResponse> adjustCredits(
            @PathVariable Long id,
            @RequestBody(required = false) AdminUserCreditsRequest request) {
        return Result.success(adminUserService.adjustCredits(id, request));
    }

    @PutMapping("/{id}/status")
    public Result<AdminUserResponse> updateStatus(
            @PathVariable Long id,
            @RequestBody(required = false) AdminUserStatusRequest request) {
        return Result.success(adminUserService.updateStatus(id, request));
    }

    @PostMapping("/{id}/reset-password")
    public Result<AdminResetPasswordResponse> resetPassword(
            @PathVariable Long id,
            @RequestBody(required = false) AdminResetPasswordRequest request) {
        return Result.success(
                adminUserService.resetPassword(
                        id,
                        request == null ? null : request.newPassword()
                )
        );
    }
}
