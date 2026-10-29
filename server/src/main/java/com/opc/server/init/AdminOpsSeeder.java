package com.opc.server.init;

import com.opc.server.entity.Agent;
import com.opc.server.entity.CreditTransaction;
import com.opc.server.entity.GatewayEndpoint;
import com.opc.server.entity.User;
import com.opc.server.repository.AgentRepository;
import com.opc.server.repository.CreditTransactionRepository;
import com.opc.server.repository.GatewayEndpointRepository;
import com.opc.server.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/** 运营演示数据：近 14 天算力流水 + 2 个网关接口定义。 */
@Component
@Order(7)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled",
        havingValue = "true", matchIfMissing = true)
public class AdminOpsSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminOpsSeeder.class);

    private final CreditTransactionRepository txnRepository;
    private final UserRepository userRepository;
    private final GatewayEndpointRepository gatewayRepository;
    private final AgentRepository agentRepository;

    public AdminOpsSeeder(CreditTransactionRepository txnRepository,
                          UserRepository userRepository,
                          GatewayEndpointRepository gatewayRepository,
                          AgentRepository agentRepository) {
        this.txnRepository = txnRepository;
        this.userRepository = userRepository;
        this.gatewayRepository = gatewayRepository;
        this.agentRepository = agentRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        seedTransactions();
        seedGateway();
    }

    private void seedTransactions() {
        if (txnRepository.count() > 0) {
            log.info("算力流水已存在，跳过初始化");
            return;
        }
        User demo = userRepository.findByUsernameAndDeletedFalse("demo").orElse(null);
        if (demo == null) {
            log.warn("未找到 demo 用户，跳过算力流水初始化");
            return;
        }

        int balance = demo.getCredits() == null ? 0 : demo.getCredits();
        List<CreditTransaction> rows = new ArrayList<>();

        int[] rechargeDays = {13, 10, 7, 4, 1};
        int[] rechargeAmounts = {198, 68, 498, 198, 298};
        String[] channels = {"微信支付", "支付宝", "微信支付", "支付宝", "微信支付"};
        for (int i = 0; i < rechargeDays.length; i++) {
            int credits = rechargeAmounts[i];
            rows.add(CreditTransaction.builder()
                    .userId(demo.getId())
                    .type("RECHARGE")
                    .amount(credits)
                    .balanceAfter(balance)
                    .moneyAmount(BigDecimal.valueOf(credits))
                    .orderNo("P" + stamp(rechargeDays[i]) + String.format("%03d", i))
                    .channel(channels[i])
                    .status("SUCCESS")
                    .remark("演示充值")
                    .build());
        }

        int[] consumeDays = {12, 11, 9, 8, 6, 5, 3, 2, 1, 0};
        int[] costs = {10, 15, 10, 10, 15, 10, 15, 10, 10, 15};
        for (int i = 0; i < consumeDays.length; i++) {
            rows.add(CreditTransaction.builder()
                    .userId(demo.getId())
                    .type("CONSUME")
                    .amount(-costs[i])
                    .balanceAfter(balance)
                    .moneyAmount(null)
                    .orderNo("C" + stamp(consumeDays[i]) + String.format("%03d", i))
                    .channel("算力余额")
                    .status("SUCCESS")
                    .remark("演示任务消耗")
                    .build());
        }

        for (int i = 0; i < rows.size(); i++) {
            CreditTransaction row = rows.get(i);
            int offset = i < rechargeDays.length ? rechargeDays[i] : consumeDays[i - rechargeDays.length];
            row.setCreatedAt(LocalDateTime.now().minusDays(offset)
                    .withHour(10 + (i % 8)).withMinute((i * 7) % 60).withSecond(0).withNano(0));
        }
        txnRepository.saveAll(rows);
        log.info("已初始化 {} 条算力流水", rows.size());
    }

    private void seedGateway() {
        if (gatewayRepository.countByDeletedFalse() > 0) {
            log.info("网关接口已存在，跳过初始化");
            return;
        }
        Agent picker = agentRepository.findByCodeAndDeletedFalse("cross-border-picker").orElse(null);
        Agent script = agentRepository.findByCodeAndDeletedFalse("short-video-script").orElse(null);
        List<GatewayEndpoint> rows = new ArrayList<>();
        if (picker != null) {
            rows.add(GatewayEndpoint.builder()
                    .name("跨境电商选品助手 API")
                    .method("POST")
                    .path("/v1/agents/cross-border-picker")
                    .agentId(picker.getId())
                    .authRequired(true)
                    .rateLimit("60/min")
                    .online(true)
                    .callCount(0L)
                    .remark("对外暴露选品助手")
                    .deleted(false)
                    .build());
        }
        if (script != null) {
            rows.add(GatewayEndpoint.builder()
                    .name("短视频脚本生成 API")
                    .method("POST")
                    .path("/v1/agents/short-video-script")
                    .agentId(script.getId())
                    .authRequired(true)
                    .rateLimit("30/min")
                    .online(true)
                    .callCount(0L)
                    .remark("对外暴露脚本生成器")
                    .deleted(false)
                    .build());
        }
        gatewayRepository.saveAll(rows);
        log.info("已初始化 {} 个网关接口", rows.size());
    }

    private static String stamp(int dayOffset) {
        return LocalDateTime.now().minusDays(dayOffset)
                .format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMdd"));
    }
}
