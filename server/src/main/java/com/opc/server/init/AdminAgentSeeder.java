package com.opc.server.init;

import com.opc.server.dto.AgentCreateRequest;
import com.opc.server.dto.AgentResponse;
import com.opc.server.dto.AgentSaveRequest;
import com.opc.server.repository.AgentRepository;
import com.opc.server.repository.AiProviderConfigRepository;
import com.opc.server.service.AgentService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * 管理端智能体演示数据（后端线负责）。
 *
 * <p>依赖 {@link AdminCoreSeeder}（{@code @Order(2)}）先初始化模型配置；
 * 这里用 {@link AgentService} 建智能体和编排，保证版本快照与线上逻辑一致。
 */
@Component
@Order(3)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled",
        havingValue = "true", matchIfMissing = true)
public class AdminAgentSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminAgentSeeder.class);

    private final AgentRepository agentRepository;
    private final AgentService agentService;
    private final AiProviderConfigRepository providerRepository;

    public AdminAgentSeeder(AgentRepository agentRepository,
                            AgentService agentService,
                            AiProviderConfigRepository providerRepository) {
        this.agentRepository = agentRepository;
        this.agentService = agentService;
        this.providerRepository = providerRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (agentRepository.countByDeletedFalse() > 0) {
            log.info("智能体已存在，跳过初始化");
            return;
        }

        Long gemId = providerId("KJ-gp");
        Long imageId = providerId("DE-TT-oai-pro");
        Long fallback = providerRepository
                .findByOnlineTrueAndDeletedFalseOrderBySortOrderAscIdAsc()
                .stream().findFirst()
                .map(provider -> provider.getId())
                .orElse(null);

        if (gemId == null) {
            gemId = fallback;
        }
        if (imageId == null) {
            imageId = fallback;
        }
        if (gemId == null) {
            log.warn("没有可用的模型配置，跳过智能体初始化");
            return;
        }

        seedPickerAgent(gemId, imageId);
        seedScriptAgent(gemId);
        log.info("已初始化 2 个演示智能体");
    }

    private void seedPickerAgent(Long gemId, Long imageId) {
        AgentResponse created = agentService.create(new AgentCreateRequest(
                "跨境电商选品助手",
                "cross-border-picker",
                "MARKETING",
                "面向东南亚市场的选品与商品主图生成助手",
                "🤖"
        ));

        List<AgentSaveRequest.Node> nodes = new ArrayList<>();
        nodes.add(new AgentSaveRequest.Node(
                "n1", "意图识别", 0, true,
                "MODEL", gemId, "MODEL_CALL", "GEM 3.7 flash",
                "{\"prompt\":\"识别用户意图\"}", null, null));
        nodes.add(new AgentSaveRequest.Node(
                "n2", "联网搜索", 1, true,
                "BUILTIN", null, "WEB_SEARCH", "联网搜索",
                "{\"query\":\"{{input}}\"}", "选品,爆品", "n3"));
        if (imageId != null) {
            nodes.add(new AgentSaveRequest.Node(
                    "n3", "商品主图生成", 2, true,
                    "MODEL", imageId, "MODEL_CALL", "TT Image 2",
                    "{\"prompt\":\"生成电商主图\"}", null, null));
        }

        agentService.save(created.id(), new AgentSaveRequest(
                "跨境电商选品助手",
                "cross-border-picker",
                "MARKETING",
                "面向东南亚市场的选品与商品主图生成助手",
                "🤖",
                gemId,
                "你是跨境电商选品专家，熟悉东南亚主流平台的选品逻辑、合规要求与物流成本。",
                "你好，告诉我目标市场与品类，我来帮你选品。",
                new AgentSaveRequest.Billing(
                        new BigDecimal("2.0"), 8, 60, 5000, false, true),
                nodes
        ));
        agentService.publish(created.id());
    }

    private void seedScriptAgent(Long gemId) {
        AgentResponse created = agentService.create(new AgentCreateRequest(
                "短视频脚本生成器",
                "short-video-script",
                "MARKETING",
                "根据商品卖点生成可直接拍摄的短视频脚本",
                "🎬"
        ));

        List<AgentSaveRequest.Node> nodes = List.of(
                new AgentSaveRequest.Node(
                        "n1", "需求理解", 0, true,
                        "MODEL", gemId, "MODEL_CALL", "GEM 3.7 flash",
                        "{\"prompt\":\"理解商品卖点\"}", null, null),
                new AgentSaveRequest.Node(
                        "n2", "脚本生成", 1, true,
                        "MODEL", gemId, "MODEL_CALL", "GEM 3.7 flash",
                        "{\"prompt\":\"生成短视频脚本\"}", null, null)
        );

        agentService.save(created.id(), new AgentSaveRequest(
                "短视频脚本生成器",
                "short-video-script",
                "MARKETING",
                "根据商品卖点生成可直接拍摄的短视频脚本",
                "🎬",
                gemId,
                "你是短视频编导，擅长把商品卖点转成 30 秒内的口播脚本。",
                "告诉我商品和卖点，我来写脚本。",
                new AgentSaveRequest.Billing(
                        new BigDecimal("1.5"), 6, 45, 3000, false, true),
                nodes
        ));
    }

    private Long providerId(String channel) {
        return providerRepository.findByChannelAndDeletedFalse(channel)
                .map(provider -> provider.getId())
                .orElse(null);
    }
}
