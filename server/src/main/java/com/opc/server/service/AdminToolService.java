package com.opc.server.service;

import com.opc.server.admin.tool.ToolKeys;
import com.opc.server.dto.AdminToolResponse;
import com.opc.server.entity.AiProviderConfig;
import com.opc.server.entity.enums.ProviderType;
import com.opc.server.entity.enums.ToolKind;
import com.opc.server.entity.enums.ToolSource;
import com.opc.server.repository.AiProviderConfigRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * 统一工具库（{@code GET /api/admin/tools}）。
 *
 * <p>工作台编排时从这个接口挑选能力。当前 P2 返回：
 * 内置工具 6 个 + 已上架模型若干；
 * MCP（P4）与知识库（P5）上线后自动追加，返回形状不变。
 */
@Service
public class AdminToolService {

    private final AiProviderConfigRepository providerRepository;

    public AdminToolService(AiProviderConfigRepository providerRepository) {
        this.providerRepository = providerRepository;
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

        // P4（MCP）/ P5（知识库）实现后在这里追加，返回结构不变
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
