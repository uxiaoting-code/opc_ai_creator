package com.opc.server.controller.admin;

import com.opc.server.common.Result;
import com.opc.server.dto.AdminToolResponse;
import com.opc.server.service.AdminToolService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 统一工具库：工作台「添加 Skill」弹窗从这里取数据。 */
@RestController
@RequestMapping("/api/admin/tools")
public class AdminToolController {

    private final AdminToolService toolService;

    public AdminToolController(AdminToolService toolService) {
        this.toolService = toolService;
    }

    @GetMapping
    public Result<List<AdminToolResponse>> list() {
        return Result.success(toolService.listTools());
    }
}
