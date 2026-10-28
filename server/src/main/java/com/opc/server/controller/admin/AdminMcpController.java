package com.opc.server.controller.admin;

import com.opc.server.common.Result;
import com.opc.server.dto.McpEnableRequest;
import com.opc.server.dto.McpInvokeRequest;
import com.opc.server.dto.McpInvokeResponse;
import com.opc.server.dto.McpServerRequest;
import com.opc.server.dto.McpServerResponse;
import com.opc.server.dto.McpToolResponse;
import com.opc.server.service.McpService;
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

import java.util.List;

/** 管理端「MCP 接入」接口（需求 3.3）。 */
@RestController
@RequestMapping("/api/admin/mcp")
public class AdminMcpController {

    private final McpService mcpService;

    public AdminMcpController(McpService mcpService) {
        this.mcpService = mcpService;
    }

    @GetMapping("/servers")
    public Result<List<McpServerResponse>> servers() {
        return Result.success(mcpService.listServers());
    }

    @PostMapping("/servers")
    public Result<McpServerResponse> create(@Valid @RequestBody McpServerRequest request) {
        return Result.success(mcpService.createServer(request));
    }

    @PutMapping("/servers/{id}")
    public Result<McpServerResponse> update(@PathVariable Long id,
                                            @Valid @RequestBody McpServerRequest request) {
        return Result.success(mcpService.updateServer(id, request));
    }

    @DeleteMapping("/servers/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        mcpService.deleteServer(id);
        return Result.success();
    }

    /** 发现能力：拉取该 MCP Server 暴露的工具列表。 */
    @PostMapping("/servers/{id}/discover")
    public Result<List<McpToolResponse>> discover(@PathVariable Long id) {
        return Result.success(mcpService.discover(id));
    }

    @GetMapping("/servers/{id}/tools")
    public Result<List<McpToolResponse>> tools(@PathVariable Long id) {
        return Result.success(mcpService.listTools(id));
    }

    /** 兼容契约里的简写：GET /api/admin/mcp/tools?serverId= */
    @GetMapping("/tools")
    public Result<List<McpToolResponse>> toolsByServer(@RequestParam Long serverId) {
        return Result.success(mcpService.listTools(serverId));
    }

    @PutMapping("/tools/{id}/enable")
    public Result<McpToolResponse> enable(@PathVariable Long id,
                                          @RequestBody McpEnableRequest request) {
        return Result.success(mcpService.enableTool(id,
                request != null && Boolean.TRUE.equals(request.enabled())));
    }

    @PostMapping("/tools/{id}/invoke")
    public Result<McpInvokeResponse> invoke(@PathVariable Long id,
                                            @RequestBody(required = false) McpInvokeRequest request) {
        return Result.success(mcpService.invoke(id, request));
    }
}
