package com.opc.server.controller.admin;

import com.opc.server.common.Result;
import com.opc.server.dto.SystemSettingRequest;
import com.opc.server.dto.SystemSettingResponse;
import com.opc.server.service.AdminSettingService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 管理端系统设置接口。
 *
 * <p>ADMIN 身份由 {@code AuthInterceptor} 统一拦截。更新方法在 Service 内还会
 * 再做一次角色校验，避免将来路由配置变化时绕过修改权限。
 */
@RestController
@RequestMapping("/api/admin/settings")
public class AdminSettingController {

    private final AdminSettingService settingService;

    public AdminSettingController(AdminSettingService settingService) {
        this.settingService = settingService;
    }

    @GetMapping
    public Result<SystemSettingResponse> getSettings() {
        return Result.success(settingService.getSettings());
    }

    @PutMapping
    public Result<SystemSettingResponse> updateSettings(
            @RequestBody(required = false) SystemSettingRequest request) {
        return Result.success(settingService.updateSettings(request));
    }
}
