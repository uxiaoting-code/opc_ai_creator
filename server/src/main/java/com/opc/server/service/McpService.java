package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.McpInvokeRequest;
import com.opc.server.dto.McpInvokeResponse;
import com.opc.server.dto.McpServerRequest;
import com.opc.server.dto.McpServerResponse;
import com.opc.server.dto.McpToolResponse;
import com.opc.server.entity.McpServer;
import com.opc.server.entity.McpTool;
import com.opc.server.repository.McpServerRepository;
import com.opc.server.repository.McpToolRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * MCP 接入服务（需求 3.3）。
 *
 * <p>实现「注册 → 发现 → 启用 → 映射到工具库 → 试调用」五步。
 * 真正的 MCP 全协议不在课设范围内；HTTP 传输按
 * {@code GET {endpoint}/tools} 与 {@code POST {endpoint}/invoke} 做发现与调用，
 * {@code mock://} 开头的地址返回演示工具。
 */
@Service
public class McpService {

    private static final Logger log = LoggerFactory.getLogger(McpService.class);
    private static final Set<String> TRANSPORTS = Set.of("HTTP", "SSE", "STDIO");

    private final McpServerRepository serverRepository;
    private final McpToolRepository toolRepository;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public McpService(McpServerRepository serverRepository,
                      McpToolRepository toolRepository,
                      ObjectMapper objectMapper) {
        this.serverRepository = serverRepository;
        this.toolRepository = toolRepository;
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();
    }

    // =========================================================================
    // 服务端
    // =========================================================================

    @Transactional(readOnly = true)
    public List<McpServerResponse> listServers() {
        return serverRepository.findAllByDeletedFalseOrderByIdAsc().stream()
                .map(this::toServerResponse)
                .toList();
    }

    @Transactional
    public McpServerResponse createServer(McpServerRequest request) {
        String transport = requireTransport(request.transport());
        McpServer server = McpServer.builder()
                .name(request.name().trim())
                .transport(transport)
                .endpoint(trimToNull(request.endpoint()))
                .command(trimToNull(request.command()))
                .envJson(trimToNull(request.envJson()))
                .authType(defaultIfBlank(request.authType(), "NONE").toUpperCase())
                .apiKey(trimToNull(request.apiKey()))
                .status("OFFLINE")
                .toolCount(0)
                .deleted(false)
                .build();
        return toServerResponse(serverRepository.save(server));
    }

    @Transactional
    public McpServerResponse updateServer(Long id, McpServerRequest request) {
        McpServer server = loadServer(id);
        server.setName(request.name().trim());
        server.setTransport(requireTransport(request.transport()));
        server.setEndpoint(trimToNull(request.endpoint()));
        server.setCommand(trimToNull(request.command()));
        server.setEnvJson(trimToNull(request.envJson()));
        server.setAuthType(defaultIfBlank(request.authType(), "NONE").toUpperCase());
        if (request.apiKey() != null && !request.apiKey().isBlank()
                && !request.apiKey().startsWith("****")) {
            server.setApiKey(request.apiKey().trim());
        }
        return toServerResponse(serverRepository.save(server));
    }

    @Transactional
    public void deleteServer(Long id) {
        McpServer server = loadServer(id);
        server.setDeleted(true);
        server.setStatus("OFFLINE");
        serverRepository.save(server);

        for (McpTool tool : toolRepository.findByServerIdAndDeletedFalseOrderByIdAsc(id)) {
            tool.setDeleted(true);
            tool.setEnabled(false);
            toolRepository.save(tool);
        }
    }

    // =========================================================================
    // 发现 / 工具
    // =========================================================================

    @Transactional
    public List<McpToolResponse> discover(Long serverId) {
        McpServer server = loadServer(serverId);
        List<ToolDef> defs = discoverRemote(server);

        List<McpTool> saved = new ArrayList<>();
        for (ToolDef def : defs) {
            McpTool tool = toolRepository
                    .findByServerIdAndToolNameAndDeletedFalse(serverId, def.name())
                    .orElseGet(McpTool::new);
            tool.setServerId(serverId);
            tool.setToolName(def.name());
            tool.setToolKey(toolKey(serverId, def.name()));
            tool.setDisplayName(defaultIfBlank(def.displayName(), def.name()));
            tool.setDescription(trimToNull(def.description()));
            tool.setInputSchema(def.inputSchema());
            tool.setEnabled(tool.getEnabled() == null || tool.getEnabled());
            tool.setDeleted(false);
            saved.add(toolRepository.save(tool));
        }

        server.setLastDiscoverAt(LocalDateTime.now());
        server.setToolCount(saved.size());
        server.setStatus("ONLINE");
        serverRepository.save(server);

        log.info("MCP 服务 {} 发现 {} 个工具", server.getName(), saved.size());
        return saved.stream().map(McpToolResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public List<McpToolResponse> listTools(Long serverId) {
        loadServer(serverId);
        return toolRepository.findByServerIdAndDeletedFalseOrderByIdAsc(serverId).stream()
                .map(McpToolResponse::from)
                .toList();
    }

    @Transactional
    public McpToolResponse enableTool(Long toolId, boolean enabled) {
        McpTool tool = loadTool(toolId);
        tool.setEnabled(enabled);
        return McpToolResponse.from(toolRepository.save(tool));
    }

    @Transactional
    public McpInvokeResponse invoke(Long toolId, McpInvokeRequest request) {
        McpTool tool = loadTool(toolId);
        McpServer server = loadServer(tool.getServerId());
        Map<String, Object> params = request == null || request.params() == null
                ? Map.of() : request.params();

        long start = System.currentTimeMillis();
        try {
            String result = invokeRemote(server, tool, params);
            tool.setLastInvokedAt(LocalDateTime.now());
            toolRepository.save(tool);
            return new McpInvokeResponse(true,
                    System.currentTimeMillis() - start, result, null);
        } catch (Exception e) {
            log.warn("MCP 工具调用失败 {}：{}", tool.getToolKey(), e.getMessage());
            return new McpInvokeResponse(false,
                    System.currentTimeMillis() - start, null, e.getMessage());
        }
    }

    // =========================================================================
    // 远程 / 演示
    // =========================================================================

    private List<ToolDef> discoverRemote(McpServer server) {
        String endpoint = server.getEndpoint();
        if (endpoint == null || endpoint.isBlank() || endpoint.startsWith("mock://")
                || !"HTTP".equalsIgnoreCase(server.getTransport())) {
            return mockTools();
        }

        String url = endpoint.endsWith("/tools")
                ? endpoint
                : endpoint.replaceAll("/$", "") + "/tools";
        try {
            HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(10))
                    .GET();
            applyAuth(builder, server);
            HttpResponse<String> response = httpClient.send(builder.build(),
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new BizException(ErrorCode.MCP_DISCOVER_FAILED,
                        "MCP 服务返回 HTTP " + response.statusCode());
            }
            JsonNode root = objectMapper.readTree(response.body());
            JsonNode array = root.isArray() ? root : root.get("tools");
            if (array == null || !array.isArray()) {
                throw new BizException(ErrorCode.MCP_DISCOVER_FAILED,
                        "响应中没有 tools 数组");
            }
            List<ToolDef> defs = new ArrayList<>();
            for (JsonNode node : array) {
                String name = node.path("name").asText();
                if (name.isBlank()) {
                    continue;
                }
                String displayName = node.has("displayName")
                        ? node.path("displayName").asText(name)
                        : node.path("display_name").asText(name);
                JsonNode schema = node.has("inputSchema")
                        ? node.get("inputSchema") : node.get("input_schema");
                defs.add(new ToolDef(name, displayName,
                        node.path("description").asText(""),
                        schema == null ? "{}" : schema.toString()));
            }
            return defs;
        } catch (BizException e) {
            throw e;
        } catch (Exception e) {
            throw new BizException(ErrorCode.MCP_DISCOVER_FAILED,
                    "无法连接 MCP 服务：" + e.getMessage());
        }
    }

    private String invokeRemote(McpServer server, McpTool tool, Map<String, Object> params) {
        String endpoint = server.getEndpoint();
        if (endpoint == null || endpoint.isBlank() || endpoint.startsWith("mock://")
                || !"HTTP".equalsIgnoreCase(server.getTransport())) {
            return mockResult(tool.getToolName());
        }

        String url = endpoint.endsWith("/invoke")
                ? endpoint
                : endpoint.replaceAll("/$", "") + "/invoke";
        try {
            String body = objectMapper.writeValueAsString(Map.of(
                    "tool", tool.getToolName(),
                    "params", params
            ));
            HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(Math.max(5, 30)))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8));
            applyAuth(builder, server);
            HttpResponse<String> response = httpClient.send(builder.build(),
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new BizException(ErrorCode.MCP_INVOKE_FAILED,
                        "MCP 服务返回 HTTP " + response.statusCode());
            }
            return response.body();
        } catch (BizException e) {
            throw e;
        } catch (Exception e) {
            throw new BizException(ErrorCode.MCP_INVOKE_FAILED,
                    "调用失败：" + e.getMessage());
        }
    }

    private void applyAuth(HttpRequest.Builder builder, McpServer server) {
        if (server.getApiKey() == null || server.getApiKey().isBlank()) {
            return;
        }
        if ("API_KEY".equalsIgnoreCase(server.getAuthType())) {
            builder.header("Authorization", "Bearer " + server.getApiKey());
        }
    }

    private List<ToolDef> mockTools() {
        return List.of(
                new ToolDef("web_search", "联网搜索", "MCP 联网搜索（演示）",
                        "{\"type\":\"object\",\"properties\":{\"query\":{\"type\":\"string\"}}}"),
                new ToolDef("code_run", "代码执行", "MCP 代码执行（演示）",
                        "{\"type\":\"object\",\"properties\":{\"code\":{\"type\":\"string\"}}}"),
                new ToolDef("human_review", "人工审核", "MCP 人工审核（演示）",
                        "{\"type\":\"object\",\"properties\":{\"content\":{\"type\":\"string\"}}}")
        );
    }

    private String mockResult(String toolName) {
        return switch (toolName) {
            case "web_search" -> "{\"results\":[{\"title\":\"东南亚夏季家居热销榜\",\"url\":\"https://example.com\"}]}";
            case "code_run" -> "{\"output\":\"12\"}";
            case "human_review" -> "{\"approved\":true}";
            default -> "{\"ok\":true}";
        };
    }

    private String toolKey(Long serverId, String toolName) {
        String safe = toolName.replaceAll("[^A-Za-z0-9_]", "_");
        return "mcp_" + serverId + "_" + safe;
    }

    // =========================================================================
    // 工具
    // =========================================================================

    private McpServer loadServer(Long id) {
        return serverRepository.findByIdAndDeletedFalse(id)
                .orElseThrow(() -> new BizException(ErrorCode.MCP_SERVER_NOT_FOUND));
    }

    private McpTool loadTool(Long id) {
        return toolRepository.findByIdAndDeletedFalse(id)
                .orElseThrow(() -> new BizException(ErrorCode.MCP_TOOL_NOT_FOUND));
    }

    private McpServerResponse toServerResponse(McpServer server) {
        long enabled = toolRepository.countByServerIdAndEnabledTrueAndDeletedFalse(server.getId());
        return new McpServerResponse(
                server.getId(), server.getName(), server.getTransport(), server.getEndpoint(),
                server.getStatus(), server.getLastDiscoverAt(),
                server.getToolCount() == null ? 0 : server.getToolCount(),
                enabled, server.getCreatedAt()
        );
    }

    private String requireTransport(String transport) {
        String value = defaultIfBlank(transport, "HTTP").toUpperCase();
        if (!TRANSPORTS.contains(value)) {
            throw new BizException(ErrorCode.MCP_TRANSPORT_UNSUPPORTED,
                    "transport 必须是 HTTP / SSE / STDIO");
        }
        return value;
    }

    private static String defaultIfBlank(String value, String fallback) {
        return (value == null || value.isBlank()) ? fallback : value;
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private record ToolDef(String name, String displayName,
                           String description, String inputSchema) {
    }
}
