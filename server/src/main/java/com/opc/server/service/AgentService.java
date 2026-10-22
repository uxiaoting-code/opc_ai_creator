package com.opc.server.service;

import com.opc.server.admin.tool.ToolKeys;
import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.AgentCreateRequest;
import com.opc.server.dto.AgentDetailResponse;
import com.opc.server.dto.AgentNodeResponse;
import com.opc.server.dto.AgentPreviewRequest;
import com.opc.server.dto.AgentPreviewResponse;
import com.opc.server.dto.AgentResponse;
import com.opc.server.dto.AgentSaveRequest;
import com.opc.server.dto.AgentVersionResponse;
import com.opc.server.entity.Agent;
import com.opc.server.entity.AgentNode;
import com.opc.server.entity.AgentVersion;
import com.opc.server.entity.AiProviderConfig;
import com.opc.server.entity.enums.AgentCategory;
import com.opc.server.entity.enums.AgentStatus;
import com.opc.server.entity.enums.ToolKind;
import com.opc.server.entity.enums.ToolSource;
import com.opc.server.repository.AgentNodeRepository;
import com.opc.server.repository.AgentRepository;
import com.opc.server.repository.AgentVersionRepository;
import com.opc.server.repository.AiProviderConfigRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 智能体工作台服务（需求 3.5）。
 *
 * <p>核心规则：
 * <ul>
 *   <li>节点 = 工具引用，统一用 toolSource + toolRefId + toolKey 定位；</li>
 *   <li>保存编排 = 全量 nodes 数组，按 nodeKey 对齐增删改；</li>
 *   <li>每次保存自动生成一个版本快照，支持回滚。</li>
 * </ul>
 */
@Service
public class AgentService {

    private static final Map<String, String> BUILTIN_NAMES = Map.of(
            ToolKeys.WEB_SEARCH, "联网搜索",
            ToolKeys.CODE_RUN, "代码执行",
            ToolKeys.IMAGE_PROCESS, "图像处理",
            ToolKeys.DB_QUERY, "数据查询",
            ToolKeys.HTTP_REQUEST, "HTTP 请求",
            ToolKeys.HUMAN_REVIEW, "人工审核"
    );

    private final AgentRepository agentRepository;
    private final AgentNodeRepository nodeRepository;
    private final AgentVersionRepository versionRepository;
    private final AiProviderConfigRepository providerRepository;
    private final ObjectMapper objectMapper;

    public AgentService(AgentRepository agentRepository,
                        AgentNodeRepository nodeRepository,
                        AgentVersionRepository versionRepository,
                        AiProviderConfigRepository providerRepository,
                        ObjectMapper objectMapper) {
        this.agentRepository = agentRepository;
        this.nodeRepository = nodeRepository;
        this.versionRepository = versionRepository;
        this.providerRepository = providerRepository;
        this.objectMapper = objectMapper;
    }

    // =========================================================================
    // 查询
    // =========================================================================

    @Transactional(readOnly = true)
    public PageResult<AgentResponse> list(int page, int pageSize,
                                          String keyword, String category, String status) {
        Specification<Agent> spec = (root, query, cb) ->
                cb.equal(root.get("deleted"), false);

        if (keyword != null && !keyword.isBlank()) {
            String like = "%" + keyword.trim().toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                    cb.like(cb.lower(root.<String>get("name")), like),
                    cb.like(cb.lower(root.<String>get("code")), like)
            ));
        }
        if (category != null && !category.isBlank()) {
            AgentCategory value = AgentCategory.parse(category);
            if (value == null) {
                throw new BizException(ErrorCode.ADMIN_PARAM_INVALID, "category 不合法");
            }
            spec = spec.and((root, query, cb) -> cb.equal(root.get("category"), value.name()));
        }
        if (status != null && !status.isBlank()) {
            AgentStatus value = AgentStatus.parse(status);
            if (value == null) {
                throw new BizException(ErrorCode.ADMIN_PARAM_INVALID, "status 不合法");
            }
            spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), value.name()));
        }

        int safePage = Math.max(1, page);
        int safeSize = Math.min(Math.max(1, pageSize), 100);
        Page<Agent> result = agentRepository.findAll(spec,
                PageRequest.of(safePage - 1, safeSize, Sort.by(Sort.Direction.ASC, "id")));
        return PageResult.from(result, this::toResponse);
    }

    @Transactional(readOnly = true)
    public AgentDetailResponse detail(Long id) {
        Agent agent = loadAgent(id);
        List<AgentNode> nodes = nodesOf(id);
        return toDetail(agent, nodes);
    }

    @Transactional(readOnly = true)
    public List<AgentVersionResponse> versions(Long id) {
        loadAgent(id);
        return versionRepository.findByAgentIdOrderByVersionNoDesc(id).stream()
                .map(v -> new AgentVersionResponse(
                        v.getVersionNo(), v.getRemark(), v.getOperator(), v.getCreatedAt()))
                .toList();
    }

    // =========================================================================
    // 新建 / 保存编排
    // =========================================================================

    @Transactional
    public AgentResponse create(AgentCreateRequest request) {
        String code = request.code().trim();
        if (agentRepository.existsByCodeAndDeletedFalse(code)) {
            throw new BizException(ErrorCode.AGENT_CODE_EXISTS);
        }
        AgentCategory category = requireCategory(request.category());

        Agent agent = Agent.builder()
                .name(request.name().trim())
                .code(code)
                .category(category.name())
                .description(trimToNull(request.description()))
                .icon(trimToNull(request.icon()))
                .baseCost(BigDecimal.ZERO)
                .maxRounds(8)
                .timeoutSeconds(60)
                .dailyQuota(5000)
                .allowUserSkill(false)
                .logFullConversation(true)
                .status(AgentStatus.DRAFT.name())
                .currentVersion(1)
                .todayCalls(0)
                .deleted(false)
                .build();
        agent = agentRepository.save(agent);
        createVersion(agent, List.of(), "创建智能体");
        return toResponse(agent);
    }

    @Transactional
    public AgentDetailResponse save(Long id, AgentSaveRequest request) {
        Agent agent = loadAgent(id);

        String code = request.code().trim();
        if (!code.equals(agent.getCode())
                && agentRepository.existsByCodeAndDeletedFalseAndIdNot(code, id)) {
            throw new BizException(ErrorCode.AGENT_CODE_EXISTS);
        }
        AgentCategory category = requireCategory(request.category());

        agent.setName(request.name().trim());
        agent.setCode(code);
        agent.setCategory(category.name());
        agent.setDescription(trimToNull(request.description()));
        agent.setIcon(trimToNull(request.icon()));
        agent.setModelProviderId(request.modelProviderId());
        agent.setSystemPrompt(trimToNull(request.systemPrompt()));
        agent.setGreeting(trimToNull(request.greeting()));

        AgentSaveRequest.Billing billing = request.billing();
        if (billing != null) {
            agent.setBaseCost(billing.baseCost() == null ? BigDecimal.ZERO : billing.baseCost());
            agent.setMaxRounds(normalizeInt(billing.maxRounds(), 8, 1, 100));
            agent.setTimeoutSeconds(normalizeInt(billing.timeoutSeconds(), 60, 5, 3600));
            agent.setDailyQuota(normalizeInt(billing.dailyQuota(), 5000, 0, 1_000_000));
            agent.setAllowUserSkill(Boolean.TRUE.equals(billing.allowUserSkill()));
            agent.setLogFullConversation(!Boolean.FALSE.equals(billing.logFullConversation()));
        }

        if (request.nodes() != null) {
            syncNodes(agent.getId(), request.nodes());
        }

        List<AgentNode> nodes = nodesOf(id);
        bumpVersion(agent, nodes, "保存编排");
        return toDetail(agent, nodes);
    }

    /** 导入配置 JSON：code 已存在则覆盖保存，否则先创建再保存。 */
    @Transactional
    public AgentDetailResponse importConfig(AgentSaveRequest request) {
        Optional<Agent> existing = agentRepository.findByCodeAndDeletedFalse(request.code().trim());
        Agent agent = existing.orElseGet(() -> {
            AgentResponse created = create(new AgentCreateRequest(
                    request.name(), request.code(), request.category(),
                    request.description(), request.icon()));
            return loadAgent(created.id());
        });
        return save(agent.getId(), request);
    }

    // =========================================================================
    // 节点
    // =========================================================================

    @Transactional
    public AgentNodeResponse addNode(Long agentId, AgentSaveRequest.Node request) {
        Agent agent = loadAgent(agentId);
        String key = requireNodeKey(request.nodeKey());
        if (nodeRepository.findByAgentIdAndNodeKey(agentId, key).isPresent()) {
            throw new BizException(ErrorCode.AGENT_NODE_KEY_DUPLICATE, "节点标识重复：" + key);
        }
        ToolSource source = requireToolSource(request.toolSource());
        validateNode(request, source);

        List<AgentNode> current = nodesOf(agentId);
        AgentNode node = new AgentNode();
        applyNode(node, agentId, key, request, source,
                request.orderIndex() == null ? current.size() : request.orderIndex());
        node = nodeRepository.save(node);

        bumpVersion(agent, nodesOf(agentId), "添加节点");
        return toNodeResponse(node);
    }

    @Transactional
    public AgentNodeResponse updateNode(Long agentId, Long nodeId, AgentSaveRequest.Node request) {
        Agent agent = loadAgent(agentId);
        AgentNode node = nodeRepository.findByIdAndAgentId(nodeId, agentId)
                .orElseThrow(() -> new BizException(ErrorCode.AGENT_NODE_NOT_FOUND));

        String key = requireNodeKey(request.nodeKey() == null ? node.getNodeKey() : request.nodeKey());
        if (!key.equals(node.getNodeKey())
                && nodeRepository.findByAgentIdAndNodeKey(agentId, key).isPresent()) {
            throw new BizException(ErrorCode.AGENT_NODE_KEY_DUPLICATE, "节点标识重复：" + key);
        }
        ToolSource source = requireToolSource(request.toolSource());
        validateNode(request, source);

        applyNode(node, agentId, key, request, source,
                request.orderIndex() == null ? node.getOrderIndex() : request.orderIndex());
        node = nodeRepository.save(node);

        bumpVersion(agent, nodesOf(agentId), "修改节点");
        return toNodeResponse(node);
    }

    @Transactional
    public void deleteNode(Long agentId, Long nodeId) {
        Agent agent = loadAgent(agentId);
        AgentNode node = nodeRepository.findByIdAndAgentId(nodeId, agentId)
                .orElseThrow(() -> new BizException(ErrorCode.AGENT_NODE_NOT_FOUND));
        nodeRepository.delete(node);
        bumpVersion(agent, nodesOf(agentId), "删除节点");
    }

    // =========================================================================
    // 发布 / 复制 / 回滚
    // =========================================================================

    @Transactional
    public AgentResponse publish(Long id) {
        Agent agent = loadAgent(id);
        List<AgentNode> nodes = nodesOf(id);
        if (nodes.stream().noneMatch(n -> Boolean.TRUE.equals(n.getEnabled()))) {
            throw new BizException(ErrorCode.AGENT_NO_NODES);
        }
        agent.setStatus(AgentStatus.PUBLISHED.name());
        agentRepository.save(agent);
        return toResponse(agent);
    }

    @Transactional
    public AgentResponse offline(Long id) {
        Agent agent = loadAgent(id);
        agent.setStatus(AgentStatus.OFFLINE.name());
        agentRepository.save(agent);
        return toResponse(agent);
    }

    /** 逻辑删除（契约之外的补充能力，方便运营清理误建的智能体）。 */
    @Transactional
    public void delete(Long id) {
        Agent agent = loadAgent(id);
        agent.setDeleted(true);
        agent.setStatus(AgentStatus.OFFLINE.name());
        agentRepository.save(agent);
    }

    @Transactional
    public AgentDetailResponse duplicate(Long id) {
        Agent source = loadAgent(id);
        List<AgentNode> sourceNodes = nodesOf(id);

        Agent copy = Agent.builder()
                .name(source.getName() + " 副本")
                .code(uniqueCopyCode(source.getCode()))
                .category(source.getCategory())
                .description(source.getDescription())
                .icon(source.getIcon())
                .modelProviderId(source.getModelProviderId())
                .systemPrompt(source.getSystemPrompt())
                .greeting(source.getGreeting())
                .baseCost(source.getBaseCost())
                .maxRounds(source.getMaxRounds())
                .timeoutSeconds(source.getTimeoutSeconds())
                .dailyQuota(source.getDailyQuota())
                .allowUserSkill(source.getAllowUserSkill())
                .logFullConversation(source.getLogFullConversation())
                .status(AgentStatus.DRAFT.name())
                .currentVersion(1)
                .todayCalls(0)
                .deleted(false)
                .build();
        copy = agentRepository.save(copy);

        for (AgentNode node : sourceNodes) {
            AgentNode copied = new AgentNode();
            copied.setAgentId(copy.getId());
            copied.setNodeKey(node.getNodeKey());
            copied.setName(node.getName());
            copied.setToolSource(node.getToolSource());
            copied.setToolRefId(node.getToolRefId());
            copied.setToolKey(node.getToolKey());
            copied.setToolNameSnapshot(node.getToolNameSnapshot());
            copied.setParamsJson(node.getParamsJson());
            copied.setEnabled(node.getEnabled());
            copied.setOrderIndex(node.getOrderIndex());
            copied.setRouteKeywords(node.getRouteKeywords());
            copied.setRouteTargetKey(node.getRouteTargetKey());
            nodeRepository.save(copied);
        }

        List<AgentNode> copiedNodes = nodesOf(copy.getId());
        createVersion(copy, copiedNodes, "复制自 " + source.getCode());
        return toDetail(copy, copiedNodes);
    }

    @Transactional
    public AgentDetailResponse rollback(Long id, Integer versionNo) {
        loadAgent(id);
        AgentVersion version = versionRepository.findByAgentIdAndVersionNo(id, versionNo)
                .orElseThrow(() -> new BizException(ErrorCode.AGENT_VERSION_NOT_FOUND));
        AgentSaveRequest snapshot;
        try {
            snapshot = objectMapper.readValue(version.getSnapshotJson(), AgentSaveRequest.class);
        } catch (Exception e) {
            throw new BizException(ErrorCode.AGENT_VERSION_NOT_FOUND, "版本快照损坏，无法回滚");
        }
        return save(id, snapshot);
    }

    // =========================================================================
    // 预览（P2 先模拟执行轨迹，不扣真实算力）
    // =========================================================================

    @Transactional(readOnly = true)
    public AgentPreviewResponse preview(Long id, AgentPreviewRequest request) {
        Agent agent = loadAgent(id);
        List<AgentNode> nodes = nodesOf(id).stream()
                .filter(n -> Boolean.TRUE.equals(n.getEnabled()))
                .toList();

        String input = (request == null || request.input() == null || request.input().isBlank())
                ? "测试输入" : request.input().trim();

        List<AgentPreviewResponse.Step> steps = new ArrayList<>();
        long totalElapsedMs = 0L;
        BigDecimal totalCredits = agent.getBaseCost() == null ? BigDecimal.ZERO : agent.getBaseCost();
        String lastOutput = null;

        for (int i = 0; i < nodes.size(); i++) {
            AgentNode node = nodes.get(i);
            String kind = resolveKind(node.getToolSource(), node.getToolKey());
            long elapsedMs = 180L + i * 120L;
            BigDecimal credits = BigDecimal.valueOf(0.8 + i * 0.2);
            String output = previewOutput(kind, input);
            steps.add(new AgentPreviewResponse.Step(
                    node.getId(), node.getNodeKey(), node.getName(), kind,
                    true, elapsedMs, credits, input, output, null));
            totalElapsedMs += elapsedMs;
            totalCredits = totalCredits.add(credits);
            lastOutput = output;
        }

        if (lastOutput == null) {
            lastOutput = "没有启用的节点，请先在编排中添加节点";
        }
        return new AgentPreviewResponse(
                "s-" + System.currentTimeMillis(), totalElapsedMs, totalCredits,
                !steps.isEmpty(), lastOutput, steps);
    }

    // =========================================================================
    // 映射
    // =========================================================================

    private AgentResponse toResponse(Agent agent) {
        List<AgentNode> nodes = nodesOf(agent.getId());
        long modelCount = nodes.stream()
                .filter(n -> ToolSource.MODEL.name().equals(n.getToolSource()))
                .map(AgentNode::getToolRefId)
                .filter(Objects::nonNull)
                .distinct()
                .count();
        int enabledCount = (int) nodes.stream()
                .filter(n -> Boolean.TRUE.equals(n.getEnabled()))
                .count();

        return new AgentResponse(
                agent.getId(), agent.getName(), agent.getCode(), agent.getCategory(),
                AgentCategory.labelOf(agent.getCategory()), agent.getDescription(), agent.getIcon(),
                agent.getModelProviderId(), modelCount, nodes.size(), enabledCount,
                agent.getTodayCalls() == null ? 0 : agent.getTodayCalls(),
                agent.getAvgElapsedMs(), agent.getSuccessRate(),
                agent.getStatus(), AgentStatus.labelOf(agent.getStatus()),
                agent.getCurrentVersion() == null ? 0 : agent.getCurrentVersion(),
                agent.getUpdatedAt()
        );
    }

    private AgentDetailResponse toDetail(Agent agent, List<AgentNode> nodes) {
        AgentDetailResponse.Billing billing = new AgentDetailResponse.Billing(
                agent.getBaseCost(), agent.getMaxRounds(), agent.getTimeoutSeconds(),
                agent.getDailyQuota(), agent.getAllowUserSkill(), agent.getLogFullConversation());

        return new AgentDetailResponse(
                agent.getId(), agent.getName(), agent.getCode(), agent.getCategory(),
                AgentCategory.labelOf(agent.getCategory()), agent.getDescription(), agent.getIcon(),
                agent.getModelProviderId(), providerName(agent), agent.getSystemPrompt(),
                agent.getGreeting(), billing,
                nodes.stream().map(this::toNodeResponse).toList(),
                agent.getStatus(), AgentStatus.labelOf(agent.getStatus()),
                agent.getCurrentVersion() == null ? 0 : agent.getCurrentVersion(),
                agent.getCreatedAt(), agent.getUpdatedAt()
        );
    }

    private AgentNodeResponse toNodeResponse(AgentNode node) {
        String kind = resolveKind(node.getToolSource(), node.getToolKey());
        ToolSource source = ToolSource.parse(node.getToolSource());
        return new AgentNodeResponse(
                node.getId(), node.getNodeKey(), node.getName(),
                node.getOrderIndex() == null ? 0 : node.getOrderIndex(),
                Boolean.TRUE.equals(node.getEnabled()),
                node.getToolSource(), source == null ? node.getToolSource() : source.getLabel(),
                node.getToolRefId(), node.getToolKey(), kind, ToolKind.labelOf(kind),
                node.getToolNameSnapshot(), node.getParamsJson(),
                node.getRouteKeywords(), node.getRouteTargetKey()
        );
    }

    // =========================================================================
    // 内部工具
    // =========================================================================

    private Agent loadAgent(Long id) {
        return agentRepository.findByIdAndDeletedFalse(id)
                .orElseThrow(() -> new BizException(ErrorCode.AGENT_NOT_FOUND));
    }

    private List<AgentNode> nodesOf(Long agentId) {
        return nodeRepository.findByAgentIdOrderByOrderIndexAscIdAsc(agentId);
    }

    private String providerName(Agent agent) {
        if (agent.getModelProviderId() == null) {
            return null;
        }
        return providerRepository.findByIdAndDeletedFalse(agent.getModelProviderId())
                .map(AiProviderConfig::getName)
                .orElse(null);
    }

    private AgentCategory requireCategory(String value) {
        AgentCategory category = AgentCategory.parse(value);
        if (category == null) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    "category 必须是 CUSTOMER_SERVICE / MARKETING / DESIGN / DATA_ANALYSIS / OTHER");
        }
        return category;
    }

    private ToolSource requireToolSource(String value) {
        ToolSource source = ToolSource.parse(value);
        if (source == null) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    "toolSource 必须是 MODEL / KNOWLEDGE / MCP / BUILTIN");
        }
        return source;
    }

    private String requireNodeKey(String value) {
        String key = value == null ? "" : value.trim();
        if (key.isEmpty()) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID, "nodeKey 不能为空");
        }
        return key;
    }

    private void validateNode(AgentSaveRequest.Node request, ToolSource source) {
        if (request.toolKey() == null || request.toolKey().isBlank()) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID, "toolKey 不能为空");
        }
        if (source != ToolSource.BUILTIN && request.toolRefId() == null) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    source.name() + " 节点必须指定 toolRefId");
        }
    }

    private void applyNode(AgentNode node, Long agentId, String key,
                           AgentSaveRequest.Node request, ToolSource source, int orderIndex) {
        node.setAgentId(agentId);
        node.setNodeKey(key);
        node.setName(defaultIfBlank(request.name(), key));
        node.setToolSource(source.name());
        node.setToolRefId(source == ToolSource.BUILTIN ? null : request.toolRefId());
        node.setToolKey(request.toolKey().trim());
        node.setToolNameSnapshot(defaultIfBlank(request.toolNameSnapshot(),
                resolveToolName(source, request.toolRefId(), request.toolKey())));
        node.setParamsJson(trimToNull(request.paramsJson()));
        node.setEnabled(request.enabled() == null || request.enabled());
        node.setOrderIndex(orderIndex);
        node.setRouteKeywords(trimToNull(request.routeKeywords()));
        node.setRouteTargetKey(trimToNull(request.routeTargetKey()));
    }

    private void syncNodes(Long agentId, List<AgentSaveRequest.Node> requested) {
        List<AgentNode> existing = nodesOf(agentId);
        Map<String, AgentNode> existingByKey = existing.stream()
                .collect(Collectors.toMap(AgentNode::getNodeKey, n -> n, (a, b) -> a));
        Set<String> requestedKeys = new HashSet<>();

        int index = 0;
        for (AgentSaveRequest.Node request : requested) {
            String key = requireNodeKey(request.nodeKey());
            if (!requestedKeys.add(key)) {
                throw new BizException(ErrorCode.AGENT_NODE_KEY_DUPLICATE, "节点标识重复：" + key);
            }
            ToolSource source = requireToolSource(request.toolSource());
            validateNode(request, source);

            AgentNode node = existingByKey.getOrDefault(key, new AgentNode());
            applyNode(node, agentId, key, request, source,
                    request.orderIndex() == null ? index : request.orderIndex());
            nodeRepository.save(node);
            index++;
        }

        for (AgentNode node : existing) {
            if (!requestedKeys.contains(node.getNodeKey())) {
                nodeRepository.delete(node);
            }
        }
    }

    private void bumpVersion(Agent agent, List<AgentNode> nodes, String remark) {
        int next = (agent.getCurrentVersion() == null ? 0 : agent.getCurrentVersion()) + 1;
        agent.setCurrentVersion(next);
        agentRepository.save(agent);
        createVersion(agent, nodes, remark);
    }

    private void createVersion(Agent agent, List<AgentNode> nodes, String remark) {
        AgentSaveRequest snapshot = new AgentSaveRequest(
                agent.getName(), agent.getCode(), agent.getCategory(), agent.getDescription(),
                agent.getIcon(), agent.getModelProviderId(), agent.getSystemPrompt(), agent.getGreeting(),
                new AgentSaveRequest.Billing(
                        agent.getBaseCost(), agent.getMaxRounds(), agent.getTimeoutSeconds(),
                        agent.getDailyQuota(), agent.getAllowUserSkill(), agent.getLogFullConversation()),
                nodes.stream().map(n -> new AgentSaveRequest.Node(
                        n.getNodeKey(), n.getName(), n.getOrderIndex(), n.getEnabled(),
                        n.getToolSource(), n.getToolRefId(), n.getToolKey(), n.getToolNameSnapshot(),
                        n.getParamsJson(), n.getRouteKeywords(), n.getRouteTargetKey())).toList()
        );

        String json;
        try {
            json = objectMapper.writeValueAsString(snapshot);
        } catch (Exception e) {
            throw new IllegalStateException("编排快照序列化失败", e);
        }

        versionRepository.save(AgentVersion.builder()
                .agentId(agent.getId())
                .versionNo(agent.getCurrentVersion())
                .snapshotJson(json)
                .remark(remark)
                .operator("admin")
                .build());
    }

    private String uniqueCopyCode(String baseCode) {
        String candidate = baseCode + "-copy";
        int i = 2;
        while (agentRepository.existsByCodeAndDeletedFalse(candidate)) {
            candidate = baseCode + "-copy" + i;
            i++;
        }
        return candidate;
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

    private String resolveToolName(ToolSource source, Long refId, String toolKey) {
        if (source == ToolSource.MODEL && refId != null) {
            return providerRepository.findByIdAndDeletedFalse(refId)
                    .map(AiProviderConfig::getName)
                    .orElse(toolKey);
        }
        if (source == ToolSource.BUILTIN) {
            return BUILTIN_NAMES.getOrDefault(toolKey, toolKey);
        }
        return toolKey;
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

    private static int normalizeInt(Integer value, int fallback, int min, int max) {
        if (value == null) {
            return fallback;
        }
        return Math.max(min, Math.min(max, value));
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static String defaultIfBlank(String value, String fallback) {
        return (value == null || value.isBlank()) ? fallback : value;
    }
}
