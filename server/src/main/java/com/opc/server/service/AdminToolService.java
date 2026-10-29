package com.opc.server.service;

import com.opc.server.admin.tool.ToolKeys;
import com.opc.server.dto.AdminToolResponse;
import com.opc.server.entity.AiProviderConfig;
import com.opc.server.entity.KnowledgeBase;
import com.opc.server.entity.McpTool;
import com.opc.server.entity.enums.ProviderType;
import com.opc.server.entity.enums.ToolKind;
import com.opc.server.entity.enums.ToolSource;
import com.opc.server.repository.AiProviderConfigRepository;
import com.opc.server.repository.KnowledgeBaseRepository;
import com.opc.server.repository.McpToolRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * 统一工具库（{@code GET /api/admin/tools}）。
 *
 * <p>工作台编排时从这个接口挑选能力：内置工具 + 已上架模型 + MCP 工具 + 知识库。
 * 返回结构一旦冻结，新增能力来源不需要改前端。
 */
@Service
public class AdminToolService {

    private final AiProviderConfigRepository providerRepository;
    private final McpToolRepository mcpToolRepository;
    private final KnowledgeBaseRepository knowledgeBaseRepository;

    public AdminToolService(AiProviderConfigRepository providerRepository,
                            McpToolRepository mcpToolRepository,
                            KnowledgeBaseRepository knowledgeBaseRepository) {
        this.providerRepository = providerRepository;
        this.mcpToolRepository = mcpToolRepository;
        this.knowledgeBaseRepository = knowledgeBaseRepository;
    }

    @Transactional(readOnly = true)
    public List<AdminToolResponse> listTools() {
        List<AdminToolResponse> tools = new ArrayList<>();

        tools.add(builtin(ToolKeys.WEB_SEARCH, ToolKind.WEB_SEARCH, "联网搜索", "抓取网页与搜索结果"));
        tools.add(builtin(ToolKeys.CODE_RUN, ToolKind.CODE_RUN, "代码执行", "执行代码片段并返回结果"));
        tools.add(builtin(ToolKeys.IMAGE_PROCESS, ToolKind.IMAGE_PROCESS, "图像处理", "裁剪、缩放、格式转换"));
        tools.add(builtin(ToolKeys.DB_QUERY, ToolKind.DB_QUERY, "数据查询", "查询业务数据库"));
        tools.add(builtin(ToolKeys.HTTP_REQUEST, ToolKind.HTTP_REQUEST, "HTTP 请求", "调用外部 HTTP 接口"));
        tools.add(builtin(ToolKeys.HUMAN_REVIEW, ToolKind.HUMAN_REVIEW, "人工审核", "人工确认后继续执行"));

        for (AiProviderConfig provider
                : providerRepository.findByOnlineTrueAndDeletedFalseOrderBySortOrderAscIdAsc()) {
            tools.add(new AdminToolResponse(
                    ToolSource.MODEL.name(),
                    ToolSource.MODEL.getLabel(),
                    provider.getId(),
                    ToolKeys.MODEL_CALL,
                    ToolKind.MODEL_CALL.name(),
                    ToolKind.MODEL_CALL.getLabel(),
                    provider.getName(),
                    (provider.getVendor() == null ? "" : provider.getVendor() + " / ")
                            + ProviderType.labelOf(provider.getType()),
                    true
            ));
        }

        for (McpTool tool : mcpToolRepository.findByEnabledTrueAndDeletedFalseOrderByIdAsc()) {
            tools.add(new AdminToolResponse(
                    ToolSource.MCP.name(),
                    ToolSource.MCP.getLabel(),
                    tool.getId(),
                    tool.getToolKey(),
                    ToolKind.HTTP_REQUEST.name(),
                    ToolKind.HTTP_REQUEST.getLabel(),
                    tool.getDisplayName() == null ? tool.getToolName() : tool.getDisplayName(),
                    tool.getDescription() == null ? "MCP 工具" : tool.getDescription(),
                    true
            ));
        }

        for (KnowledgeBase kb : knowledgeBaseRepository.findAllByDeletedFalseOrderByIdAsc()) {
            tools.add(new AdminToolResponse(
                    ToolSource.KNOWLEDGE.name(),
                    ToolSource.KNOWLEDGE.getLabel(),
                    kb.getId(),
                    ToolKeys.KB_RETRIEVE,
                    ToolKind.KB_RETRIEVE.name(),
                    ToolKind.KB_RETRIEVE.getLabel(),
                    kb.getName(),
                    "知识库检索（" + (kb.getChunkCount() == null ? 0 : kb.getChunkCount()) + " 个分段）",
                    true
            ));
        }

        return tools;
    }

    private AdminToolResponse builtin(String toolKey, ToolKind kind,
                                      String name, String description) {
        return new AdminToolResponse(
                ToolSource.BUILTIN.name(),
                ToolSource.BUILTIN.getLabel(),
                null,
                toolKey,
                kind.name(),
                kind.getLabel(),
                name,
                description,
                true
        );
    }
}
