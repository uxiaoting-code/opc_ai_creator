package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.GatewayEndpointRequest;
import com.opc.server.dto.GatewayEndpointResponse;
import com.opc.server.entity.GatewayEndpoint;
import com.opc.server.repository.AgentRepository;
import com.opc.server.repository.GatewayEndpointRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** 管理端「API 网关」服务（需求 1.3 的对外接口定义）。 */
@Service
public class GatewayEndpointService {

    private static final Set<String> METHODS =
            Set.of("GET", "POST", "PUT", "PATCH", "DELETE");

    private final GatewayEndpointRepository repository;
    private final AgentRepository agentRepository;
    private final ObjectMapper objectMapper;

    public GatewayEndpointService(GatewayEndpointRepository repository,
                                  AgentRepository agentRepository,
                                  ObjectMapper objectMapper) {
        this.repository = repository;
        this.agentRepository = agentRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public List<GatewayEndpointResponse> list() {
        return repository.findAllByDeletedFalseOrderByIdAsc().stream()
                .map(GatewayEndpointResponse::from).toList();
    }

    @Transactional
    public GatewayEndpointResponse create(GatewayEndpointRequest request) {
        String method = requireMethod(request.method());
        String path = requirePath(request.path());
        if (repository.existsByMethodAndPathAndDeletedFalse(method, path)) {
            throw new BizException(ErrorCode.GATEWAY_ENDPOINT_EXISTS);
        }
        validateAgent(request.agentId());

        GatewayEndpoint endpoint = GatewayEndpoint.builder()
                .name(request.name().trim())
                .method(method)
                .path(path)
                .agentId(request.agentId())
                .authRequired(request.authRequired() == null || request.authRequired())
                .rateLimit(trimToNull(request.rateLimit()))
                .online(request.online() == null || request.online())
                .callCount(0L)
                .remark(trimToNull(request.remark()))
                .deleted(false)
                .build();
        return GatewayEndpointResponse.from(repository.save(endpoint));
    }

    @Transactional
    public GatewayEndpointResponse update(Long id, GatewayEndpointRequest request) {
        GatewayEndpoint endpoint = load(id);
        String method = requireMethod(request.method());
        String path = requirePath(request.path());
        boolean duplicate = repository.findAllByDeletedFalseOrderByIdAsc().stream()
                .anyMatch(e -> !e.getId().equals(id)
                        && method.equals(e.getMethod())
                        && path.equals(e.getPath()));
        if (duplicate) {
            throw new BizException(ErrorCode.GATEWAY_ENDPOINT_EXISTS);
        }
        validateAgent(request.agentId());

        endpoint.setName(request.name().trim());
        endpoint.setMethod(method);
        endpoint.setPath(path);
        endpoint.setAgentId(request.agentId());
        endpoint.setAuthRequired(request.authRequired() == null || request.authRequired());
        endpoint.setRateLimit(trimToNull(request.rateLimit()));
        endpoint.setOnline(request.online() == null || request.online());
        endpoint.setRemark(trimToNull(request.remark()));
        return GatewayEndpointResponse.from(repository.save(endpoint));
    }

    @Transactional
    public void delete(Long id) {
        GatewayEndpoint endpoint = load(id);
        endpoint.setDeleted(true);
        repository.save(endpoint);
    }

    @Transactional(readOnly = true)
    public String exportOpenApi() {
        Map<String, Object> doc = new LinkedHashMap<>();
        doc.put("openapi", "3.0.3");
        doc.put("info", Map.of("title", "OPC AI 后台开放接口", "version", "1.0.0"));

        Map<String, Object> paths = new LinkedHashMap<>();
        for (GatewayEndpoint endpoint : repository.findAllByDeletedFalseOrderByIdAsc()) {
            Map<String, Object> operation = new LinkedHashMap<>();
            operation.put("summary", endpoint.getName());
            operation.put("operationId", "ep_" + endpoint.getId());
            operation.put("responses", Map.of("200", Map.of("description", "成功")));
            @SuppressWarnings("unchecked")
            Map<String, Object> byMethod = (Map<String, Object>) paths.computeIfAbsent(
                    endpoint.getPath(), key -> new LinkedHashMap<>());
            byMethod.put(endpoint.getMethod().toLowerCase(), operation);
        }
        doc.put("paths", paths);

        try {
            return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(doc);
        } catch (Exception e) {
            throw new BizException(ErrorCode.GATEWAY_EXPORT_FAILED,
                    "OpenAPI 导出失败：" + e.getMessage());
        }
    }

    private GatewayEndpoint load(Long id) {
        return repository.findByIdAndDeletedFalse(id)
                .orElseThrow(() -> new BizException(ErrorCode.GATEWAY_ENDPOINT_NOT_FOUND));
    }

    private void validateAgent(Long agentId) {
        if (agentId != null) {
            agentRepository.findByIdAndDeletedFalse(agentId)
                    .orElseThrow(() -> new BizException(ErrorCode.AGENT_NOT_FOUND));
        }
    }

    private String requireMethod(String method) {
        String value = (method == null || method.isBlank())
                ? "POST" : method.trim().toUpperCase();
        if (!METHODS.contains(value)) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    "method 必须是 GET / POST / PUT / PATCH / DELETE");
        }
        return value;
    }

    private String requirePath(String path) {
        String value = path == null ? "" : path.trim();
        if (value.isEmpty() || !value.startsWith("/")) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    "path 必须以 / 开头");
        }
        return value;
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
