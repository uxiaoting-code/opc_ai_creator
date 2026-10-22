package com.opc.server.controller.admin;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.AgentCreateRequest;
import com.opc.server.dto.AgentDetailResponse;
import com.opc.server.dto.AgentNodeResponse;
import com.opc.server.dto.AgentPreviewRequest;
import com.opc.server.dto.AgentPreviewResponse;
import com.opc.server.dto.AgentResponse;
import com.opc.server.dto.AgentSaveRequest;
import com.opc.server.dto.AgentVersionResponse;
import com.opc.server.service.AgentService;
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

/** 管理端「智能体 Skill 配置」接口（需求 3.5 工作台）。 */
@RestController
@RequestMapping("/api/admin/agents")
public class AdminAgentController {

    private final AgentService agentService;

    public AdminAgentController(AgentService agentService) {
        this.agentService = agentService;
    }

    @GetMapping
    public Result<PageResult<AgentResponse>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String status) {
        return Result.success(agentService.list(page, pageSize, keyword, category, status));
    }

    @PostMapping
    public Result<AgentResponse> create(@Valid @RequestBody AgentCreateRequest request) {
        return Result.success(agentService.create(request));
    }

    /** 导入配置 JSON：code 已存在则覆盖，否则新建。 */
    @PostMapping("/import")
    public Result<AgentDetailResponse> importConfig(@Valid @RequestBody AgentSaveRequest request) {
        return Result.success(agentService.importConfig(request));
    }

    @GetMapping("/{id}")
    public Result<AgentDetailResponse> detail(@PathVariable Long id) {
        return Result.success(agentService.detail(id));
    }

    /** 保存编排（全量 nodes 数组，按 nodeKey 对齐增删改）。 */
    @PutMapping("/{id}")
    public Result<AgentDetailResponse> save(@PathVariable Long id,
                                            @Valid @RequestBody AgentSaveRequest request) {
        return Result.success(agentService.save(id, request));
    }

    @PostMapping("/{id}/nodes")
    public Result<AgentNodeResponse> addNode(@PathVariable Long id,
                                             @RequestBody AgentSaveRequest.Node request) {
        return Result.success(agentService.addNode(id, request));
    }

    @PutMapping("/{id}/nodes/{nodeId}")
    public Result<AgentNodeResponse> updateNode(@PathVariable Long id,
                                                @PathVariable Long nodeId,
                                                @RequestBody AgentSaveRequest.Node request) {
        return Result.success(agentService.updateNode(id, nodeId, request));
    }

    @DeleteMapping("/{id}/nodes/{nodeId}")
    public Result<Void> deleteNode(@PathVariable Long id, @PathVariable Long nodeId) {
        agentService.deleteNode(id, nodeId);
        return Result.success();
    }

    @PostMapping("/{id}/publish")
    public Result<AgentResponse> publish(@PathVariable Long id) {
        return Result.success(agentService.publish(id));
    }

    @PostMapping("/{id}/offline")
    public Result<AgentResponse> offline(@PathVariable Long id) {
        return Result.success(agentService.offline(id));
    }

    /** 逻辑删除（契约之外的补充能力）。 */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        agentService.delete(id);
        return Result.success();
    }

    @PostMapping("/{id}/duplicate")
    public Result<AgentDetailResponse> duplicate(@PathVariable Long id) {
        return Result.success(agentService.duplicate(id));
    }

    @GetMapping("/{id}/versions")
    public Result<List<AgentVersionResponse>> versions(@PathVariable Long id) {
        return Result.success(agentService.versions(id));
    }

    @PostMapping("/{id}/versions/{versionNo}/rollback")
    public Result<AgentDetailResponse> rollback(@PathVariable Long id,
                                                @PathVariable Integer versionNo) {
        return Result.success(agentService.rollback(id, versionNo));
    }

    @PostMapping("/{id}/preview")
    public Result<AgentPreviewResponse> preview(
            @PathVariable Long id,
            @RequestBody(required = false) AgentPreviewRequest request) {
        return Result.success(agentService.preview(id, request));
    }
}
