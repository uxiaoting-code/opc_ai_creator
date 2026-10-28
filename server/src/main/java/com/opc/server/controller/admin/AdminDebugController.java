package com.opc.server.controller.admin;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.AgentPreviewResponse;
import com.opc.server.dto.DebugChainRequest;
import com.opc.server.dto.DebugChatRequest;
import com.opc.server.dto.DebugCompareResponse;
import com.opc.server.dto.DebugLogResponse;
import com.opc.server.dto.DebugNodeRequest;
import com.opc.server.dto.RegressionCaseRequest;
import com.opc.server.dto.RegressionCaseResponse;
import com.opc.server.dto.RegressionRunRequest;
import com.opc.server.dto.RegressionRunResponse;
import com.opc.server.service.DebugService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 管理端「调试面板」接口（需求 3.2）。 */
@RestController
@RequestMapping("/api/admin/debug")
public class AdminDebugController {

    private final DebugService debugService;

    public AdminDebugController(DebugService debugService) {
        this.debugService = debugService;
    }

    @PostMapping("/node")
    public Result<AgentPreviewResponse> node(@RequestBody DebugNodeRequest request) {
        return Result.success(debugService.debugNode(request));
    }

    @PostMapping("/chain")
    public Result<AgentPreviewResponse> chain(@RequestBody DebugChainRequest request) {
        return Result.success(debugService.debugChain(request));
    }

    @PostMapping("/chat")
    public Result<AgentPreviewResponse> chat(@RequestBody DebugChatRequest request) {
        return Result.success(debugService.debugChat(request));
    }

    @GetMapping("/logs")
    public Result<PageResult<DebugLogResponse>> logs(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) Long agentId,
            @RequestParam(required = false) String mode,
            @RequestParam(required = false) Boolean success) {
        return Result.success(debugService.logs(page, pageSize, agentId, mode, success));
    }

    @GetMapping("/compare")
    public Result<DebugCompareResponse> compare(
            @RequestParam Long agentId,
            @RequestParam Integer versionA,
            @RequestParam Integer versionB,
            @RequestParam(required = false) String input) {
        return Result.success(debugService.compare(agentId, versionA, versionB, input));
    }

    @GetMapping("/regression/cases")
    public Result<List<RegressionCaseResponse>> cases(@RequestParam Long agentId) {
        return Result.success(debugService.cases(agentId));
    }

    @PostMapping("/regression/cases")
    public Result<RegressionCaseResponse> createCase(
            @Valid @RequestBody RegressionCaseRequest request) {
        return Result.success(debugService.createCase(request));
    }

    @PostMapping("/regression")
    public Result<RegressionRunResponse> runRegression(
            @RequestBody RegressionRunRequest request) {
        return Result.success(debugService.runRegression(request));
    }
}
