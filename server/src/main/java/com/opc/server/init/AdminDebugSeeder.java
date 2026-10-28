package com.opc.server.init;

import com.opc.server.entity.Agent;
import com.opc.server.entity.RegressionCase;
import com.opc.server.repository.AgentRepository;
import com.opc.server.repository.RegressionCaseRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** 调试面板演示数据：给「跨境电商选品助手」预置 2 条回归用例。 */
@Component
@Order(4)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled",
        havingValue = "true", matchIfMissing = true)
public class AdminDebugSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminDebugSeeder.class);

    private final AgentRepository agentRepository;
    private final RegressionCaseRepository caseRepository;

    public AdminDebugSeeder(AgentRepository agentRepository,
                            RegressionCaseRepository caseRepository) {
        this.agentRepository = agentRepository;
        this.caseRepository = caseRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        Agent agent = agentRepository.findByCodeAndDeletedFalse("cross-border-picker").orElse(null);
        if (agent == null) {
            log.warn("未找到 cross-border-picker，跳过回归用例初始化");
            return;
        }
        if (caseRepository.countByAgentId(agent.getId()) > 0) {
            log.info("回归用例已存在，跳过初始化");
            return;
        }

        caseRepository.saveAll(List.of(
                RegressionCase.builder()
                        .agentId(agent.getId())
                        .name("东南亚家居选品")
                        .input("帮我在东南亚找一款夏季家居爆品")
                        .expectedKeywords("家居")
                        .enabled(true)
                        .createdBy("admin")
                        .build(),
                RegressionCase.builder()
                        .agentId(agent.getId())
                        .name("商品主图生成")
                        .input("生成一张商品主图")
                        .expectedKeywords("主图")
                        .enabled(true)
                        .createdBy("admin")
                        .build()
        ));
        log.info("已初始化 2 条回归用例");
    }
}
