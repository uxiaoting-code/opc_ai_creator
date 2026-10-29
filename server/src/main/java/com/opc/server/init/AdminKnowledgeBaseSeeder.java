package com.opc.server.init;

import com.opc.server.dto.KbBindAgentsRequest;
import com.opc.server.dto.KbDocumentRequest;
import com.opc.server.dto.KnowledgeBaseRequest;
import com.opc.server.dto.KnowledgeBaseResponse;
import com.opc.server.entity.Agent;
import com.opc.server.repository.AgentRepository;
import com.opc.server.repository.KnowledgeBaseRepository;
import com.opc.server.service.KnowledgeBaseService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** 知识库演示数据：一个运营知识库 + 2 篇文档，并绑定选品助手。 */
@Component
@Order(6)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled",
        havingValue = "true", matchIfMissing = true)
public class AdminKnowledgeBaseSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminKnowledgeBaseSeeder.class);

    private final KnowledgeBaseRepository kbRepository;
    private final KnowledgeBaseService kbService;
    private final AgentRepository agentRepository;

    public AdminKnowledgeBaseSeeder(KnowledgeBaseRepository kbRepository,
                                    KnowledgeBaseService kbService,
                                    AgentRepository agentRepository) {
        this.kbRepository = kbRepository;
        this.kbService = kbService;
        this.agentRepository = agentRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (kbRepository.countByDeletedFalse() > 0) {
            log.info("知识库已存在，跳过初始化");
            return;
        }

        KnowledgeBaseResponse kb = kbService.create(new KnowledgeBaseRequest(
                "平台运营知识库",
                "跨境电商选品、平台规则与内容创作规范",
                "keyword-v1"));

        kbService.addDocument(kb.id(), new KbDocumentRequest(
                "跨境选品规则",
                "TEXT",
                "跨境电商选品需要关注目标市场的季节性需求、物流成本、合规要求与竞争程度。"
                        + "夏季家居类目在东南亚市场增长明显，便携折叠收纳箱、降温用品和户外小家电是高频品类。"
                        + "选品时应优先验证毛利率、供应商稳定性与平台禁售清单，并准备商品主图与短视频素材。",
                null, null));

        kbService.addDocument(kb.id(), new KbDocumentRequest(
                "内容创作规范",
                "TEXT",
                "商品主图需要突出产品主体，背景干净，避免水印与夸大宣传。"
                        + "短视频脚本建议在前三秒给出卖点，随后展示使用场景与优惠信息。"
                        + "所有生成内容必须经过人工审核，确保符合平台规则与广告法要求。",
                null, null));

        Agent agent = agentRepository.findByCodeAndDeletedFalse("cross-border-picker").orElse(null);
        if (agent != null) {
            kbService.bindAgents(kb.id(), new KbBindAgentsRequest(List.of(agent.getId())));
        }
        log.info("已初始化知识库「{}」，并写入 2 篇文档", kb.name());
    }
}
