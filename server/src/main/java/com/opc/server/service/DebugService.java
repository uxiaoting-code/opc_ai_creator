package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.AgentPreviewResponse;
import com.opc.server.dto.AgentSaveRequest;
import com.opc.server.dto.DebugChainRequest;
import com.opc.server.dto.DebugChatRequest;
import com.opc.server.dto.DebugCompareResponse;
import com.opc.server.dto.DebugLogResponse;
import com.opc.server.dto.DebugNodeRequest;
import com.opc.server.dto.RegressionCaseRequest;
import com.opc.server.dto.RegressionCaseResponse;
import com.opc.server.dto.RegressionRunRequest;
import com.opc.server.dto.RegressionRunResponse;
import com.opc.server.entity.Agent;
import com.opc.server.entity.AgentNode;
import com.opc.server.entity.AgentVersion;
import com.opc.server.entity.CallLog;
import com.opc.server.entity.RegressionCase;
import com.opc.server.entity.enums.ToolKind;
import com.opc.server.entity.enums.ToolSource;
import com.opc.server.repository.AgentNodeRepository;
import com.opc.server.repository.AgentRepository;
import com.opc.server.repository.AgentVersionRepository;
import com.opc.server.repository.CallLogRepository;
import com.opc.server.repository.RegressionCaseRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * 管理端调试面板服务（需求 3.2）。
 *
 * <p>P3 的执行是「模拟轨迹」：不扣真实算力、不调用真实模型；
 * 但每次调试都会落 {@code t_call_log}，供「日志追踪」查询。
 */
@Service
public class DebugService {

    private final AgentRepository agentRepository;
    private final AgentNodeRepository nodeRepository;
    private final AgentVersionRepository versionRepository;
    private final CallLogRepository logRepository;
    private final RegressionCaseRepository caseRepository;
    private final ObjectMapper objectMapper;

    public DebugService(AgentRepository agentRepository,
                        AgentNodeRepository nodeRepository,
                        AgentVersionRepository versionRepository,
                        CallLogRepository logRepository,
                        RegressionCaseRepository caseRepository,
                        ObjectMapper objectMapper) {
        this.agentRepository = agentRepository;
        this.nodeRepository = nodeRepository;
        this.versionRepository = versionRepository;
        this.logRepository = logRepository;
        this.caseRepository = caseRepository;
        this.objectMapper = objectMapper;
    }

    // =========================================================================
    // 调试
    // =========================================================================

    @Transactional
    public AgentPreviewResponse debugNode(DebugNodeRequest request) {
        if (request == null || request.agentId() == null || request.nodeId() == null) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID, "agentId 和 nodeId 不能为空");
        }
        Agent agent = loadAgent(request.agentId());
        AgentNode node = nodeRepository.findByIdAndAgentId(request.nodeId(), request.agentId())
                .orElseThrow(() -> new BizException(ErrorCode.DEBUG_NODE_NOT_FOUND));

        AgentPreviewResponse trace = simulate(agent.getId(), agent.getName(), agent.getBaseCost(),
                List.of(nodeView(node)), request.input(), null);
        logTrace(agent, "NODE", trace, true);
        return trace;
    }

    @Transactional
    public AgentPreviewResponse debugChain(DebugChainRequest request) {
        if (request == null || request.agentId() == null) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID, "agentId 不能为空");
        }
        Agent agent = loadAgent(request.agentId());
        List<NodeView> nodes = enabledNodeViews(agent.getId());
        AgentPreviewResponse trace = simulate(agent.getId(), agent.getName(), agent.getBaseCost(),
                nodes, request.input(), null);
        logTrace(agent, "CHAIN", trace, !Boolean.FALSE.equals(request.saveLog()));
        return trace;
    }

    @Transactional
    public AgentPreviewResponse debugChat(DebugChatRequest request) {
        if (request == null || request.agentId() == null) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID, "agentId 不能为空");
        }
        Agent agent = loadAgent(request.agentId());
        List<NodeView> nodes = enabledNodeViews(agent.getId());
        AgentPreviewResponse trace = simulate(agent.getId(), agent.getName(), agent.getBaseCost(),
                nodes, request.message(), request.sessionId());
        logTrace(agent, "CHAT", trace, true);
        return trace;
    }

    @Transactional(readOnly = true)
    public PageResult<DebugLogResponse> logs(int page, int pageSize, Long agentId,
                                             String mode, Boolean success) {
        final String modeValue = (mode == null || mode.isBlank()) ? null : mode.trim().toUpperCase();
        Specification<CallLog> spec = (root, query, cb) -> cb.conjunction();
        if (agentId != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("agentId"), agentId));
        }
        if (modeValue != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("mode"), modeValue));
        }
        if (success != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("success"), success));
        }
        int safePage = Math.max(1, page);
        int safeSize = Math.min(Math.max(1, pageSize), 100);
        Page<CallLog> result = logRepository.findAll(spec,
                PageRequest.of(safePage - 1, safeSize, Sort.by(Sort.Direction.DESC, "id")));
        return PageResult.from(result, DebugLogResponse::from);
    }

    // =========================================================================
    // 版本对比
    // =========================================================================

    @Transactional(readOnly = true)
    public DebugCompareResponse compare(Long agentId, Integer versionA, Integer versionB, String input) {
        Agent agent = loadAgent(agentId);
        AgentSaveRequest a = loadSnapshot(agentId, versionA);
        AgentSaveRequest b = loadSnapshot(agentId, versionB);

        AgentPreviewResponse traceA = simulate(agent.getId(), agent.getName(), agent.getBaseCost(),
                snapshotNodeViews(a), input, "cmp-" + versionA + "-" + System.currentTimeMillis());
        AgentPreviewResponse traceB = simulate(agent.getId(), agent.getName(), agent.getBaseCost(),
                snapshotNodeViews(b), input, "cmp-" + versionB + "-" + System.currentTimeMillis());

        String summary = "v" + versionA + "：" + traceA.nodes().size() + " 个节点；"
                + "v" + versionB + "：" + traceB.nodes().size() + " 个节点；"
                + (safe(traceA.finalOutput()).equals(safe(traceB.finalOutput()))
                ? "最终输出一致" : "最终输出不同");

        return new DebugCompareResponse(versionA, versionB, traceA, traceB, summary);
    }

    // =========================================================================
    // 回归测试
    // =========================================================================

    @Transactional(readOnly = true)
    public List<RegressionCaseResponse> cases(Long agentId) {
        loadAgent(agentId);
        return caseRepository.findByAgentIdOrderByIdAsc(agentId).stream()
                .map(RegressionCaseResponse::from)
                .toList();
    }

    @Transactional
    public RegressionCaseResponse createCase(RegressionCaseRequest request) {
        if (request == null || request.agentId() == null) {
            throw new BizException(ErrorCode.DEBUG_CASE_INVALID, "agentId 不能为空");
        }
        loadAgent(request.agentId());
        RegressionCase saved = caseRepository.save(RegressionCase.builder()
                .agentId(request.agentId())
                .name(request.name().trim())
                .input(request.input().trim())
                .expectedKeywords(trimToNull(request.expectedKeywords()))
                .enabled(request.enabled() == null || request.enabled())
                .createdBy("admin")
                .build());
        return RegressionCaseResponse.from(saved);
    }

    @Transactional
    public RegressionRunResponse runRegression(RegressionRunRequest request) {
        if (request == null || request.agentId() == null) {
            throw new BizException(ErrorCode.DEBUG_CASE_INVALID, "agentId 不能为空");
        }
        Agent agent = loadAgent(request.agentId());
        List<RegressionCase> cases = caseRepository
                .findByAgentIdAndEnabledTrueOrderByIdAsc(request.agentId());
        List<NodeView> nodes = enabledNodeViews(agent.getId());

        List<RegressionRunResponse.Result> results = new ArrayList<>();
        int passed = 0;
        for (RegressionCase item : cases) {
            AgentPreviewResponse trace = simulate(agent.getId(), agent.getName(), agent.getBaseCost(),
                    nodes, item.getInput(), "reg-" + item.getId() + "-" + System.currentTimeMillis());
            boolean ok = keywordsMatched(item.getExpectedKeywords(), trace.finalOutput());
            if (ok) {
                passed++;
            }
            results.add(new RegressionRunResponse.Result(
                    item.getId(), item.getName(), item.getInput(), ok,
                    item.getExpectedKeywords(), trace.finalOutput(), trace.totalElapsedMs()));
            logTrace(agent, "REGRESSION", trace, true);
        }
        return new RegressionRunResponse(results.size(), passed,
                results.size() - passed, results);
    }

    // =========================================================================
    // 模拟与日志
    // =========================================================================

    private AgentPreviewResponse simulate(Long agentId, String agentName, BigDecimal baseCost,
                                          List<NodeView> nodes, String input, String sessionId) {
        String actualInput = (input == null || input.isBlank()) ? "测试输入" : input.trim();
        String sid = (sessionId == null || sessionId.isBlank())
                ? "s-" + System.currentTimeMillis() : sessionId;

        List<AgentPreviewResponse.Step> steps = new ArrayList<>();
        long totalElapsed = 0L;
        BigDecimal totalCredits = baseCost == null ? BigDecimal.ZERO : baseCost;
        String lastOutput = null;

        for (int i = 0; i < nodes.size(); i++) {
            NodeView node = nodes.get(i);
            String kind = resolveKind(node.toolSource(), node.toolKey());
            long elapsedMs = 180L + i * 120L;
            BigDecimal credits = BigDecimal.valueOf(0.8 + i * 0.2);
            String output = previewOutput(kind, actualInput);
            steps.add(new AgentPreviewResponse.Step(
                    node.id(), node.nodeKey(), node.name(), kind,
                    true, elapsedMs, credits, actualInput, output, null));
            totalElapsed += elapsedMs;
            totalCredits = totalCredits.add(credits);
            lastOutput = output;
        }

        if (lastOutput == null) {
            lastOutput = "没有启用的节点，请先在编排中添加节点";
        }
        return new AgentPreviewResponse(sid, totalElapsed, totalCredits,
                !steps.isEmpty(), lastOutput, steps);
    }

    private void logTrace(Agent agent, String mode, AgentPreviewResponse trace, boolean saveLog) {
        if (!saveLog || trace == null || trace.nodes() == null) {
            return;
        }
        for (AgentPreviewResponse.Step step : trace.nodes()) {
            logRepository.save(CallLog.builder()
                    .sessionId(trace.sessionId())
                    .agentId(agent.getId())
                    .agentName(agent.getName())
                    .mode(mode)
                    .nodeId(step.nodeId())
                    .nodeKey(step.nodeKey())
                    .nodeName(step.name())
                    .toolKind(step.toolKind())
                    .input(step.input())
                    .output(step.output())
                    .success(step.success())
                    .elapsedMs(step.elapsedMs())
                    .credits(step.credits())
                    .errorMsg(step.errorMessage())
                    .operator("admin")
                    .build());
        }
    }

    // =========================================================================
    // 工具
    // =========================================================================

    private Agent loadAgent(Long id) {
        return agentRepository.findByIdAndDeletedFalse(id)
                .orElseThrow(() -> new BizException(ErrorCode.DEBUG_AGENT_NOT_FOUND));
    }

    private List<NodeView> enabledNodeViews(Long agentId) {
        return nodeRepository.findByAgentIdOrderByOrderIndexAscIdAsc(agentId).stream()
                .filter(n -> Boolean.TRUE.equals(n.getEnabled()))
                .map(this::nodeView)
                .toList();
    }

    private NodeView nodeView(AgentNode node) {
        return new NodeView(node.getId(), node.getNodeKey(), node.getName(),
                node.getToolSource(), node.getToolKey());
    }

    private List<NodeView> snapshotNodeViews(AgentSaveRequest snapshot) {
        if (snapshot == null || snapshot.nodes() == null) {
            return List.of();
        }
        return snapshot.nodes().stream()
                .filter(n -> n.enabled() == null || n.enabled())
                .map(n -> new NodeView(null, n.nodeKey(), n.name(), n.toolSource(), n.toolKey()))
                .toList();
    }

    private AgentSaveRequest loadSnapshot(Long agentId, Integer versionNo) {
        AgentVersion version = versionRepository.findByAgentIdAndVersionNo(agentId, versionNo)
                .orElseThrow(() -> new BizException(ErrorCode.DEBUG_VERSION_NOT_FOUND));
        try {
            return objectMapper.readValue(version.getSnapshotJson(), AgentSaveRequest.class);
        } catch (Exception e) {
            throw new BizException(ErrorCode.DEBUG_VERSION_NOT_FOUND, "版本快照损坏，无法对比");
        }
    }

    private boolean keywordsMatched(String expectedKeywords, String actualOutput) {
        if (expectedKeywords == null || expectedKeywords.isBlank()) {
            return true;
        }
        String output = safe(actualOutput);
        for (String keyword : expectedKeywords.split("[,，]")) {
            String k = keyword.trim();
            if (!k.isEmpty() && !output.contains(k)) {
                return false;
            }
        }
        return true;
    }

    private String resolveKind(String source, String toolKey) {
        if (ToolSource.MODEL.name().equalsIgnoreCase(source)) {
            return ToolKind.MODEL_CALL.name();
        }
        if (ToolSource.KNOWLEDGE.name().equalsIgnoreCase(source)) {
            return ToolKind.KB_RETRIEVE.name();
        }
        ToolKind kind = ToolKind.parse(toolKey);
        return kind == null ? ToolKind.HTTP_REQUEST.name() : kind.name();
    }

    private String previewOutput(String kind, String input) {
        return switch (kind) {
            case "MODEL_CALL" -> "模型生成完成：已基于「" + input + "」输出内容";
            case "WEB_SEARCH" -> "联网检索完成，返回 12 条相关结果";
            case "KB_RETRIEVE" -> "知识库检索完成，命中 3 个相关片段";
            case "CODE_RUN" -> "代码执行成功，返回 1 个结果";
            case "IMAGE_PROCESS" -> "图像处理完成（1024×1024）";
            case "DB_QUERY" -> "数据库查询完成，返回 8 行数据";
            case "HTTP_REQUEST" -> "HTTP 请求成功，返回 JSON";
            case "HUMAN_REVIEW" -> "人工审核通过";
            default -> "节点执行完成";
        };
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private record NodeView(Long id, String nodeKey, String name,
                            String toolSource, String toolKey) {
    }
}
