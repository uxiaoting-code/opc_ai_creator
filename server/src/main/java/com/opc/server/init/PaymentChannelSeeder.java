package com.opc.server.init;

import com.opc.server.entity.PaymentChannel;
import com.opc.server.entity.enums.PaymentChannelDirection;
import com.opc.server.repository.PaymentChannelRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** 充值/提现渠道演示数据（M3）。 */
@Component
@Order(9)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled", havingValue = "true", matchIfMissing = true)
public class PaymentChannelSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(PaymentChannelSeeder.class);

    private final PaymentChannelRepository channelRepository;

    public PaymentChannelSeeder(PaymentChannelRepository channelRepository) {
        this.channelRepository = channelRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (channelRepository.count() > 0) {
            log.info("支付渠道已存在，跳过初始化");
            return;
        }
        List<PaymentChannel> channels = List.of(
                channel("ALIPAY", "支付宝", PaymentChannelDirection.BOTH, "alipay", 100, 500000, 10),
                channel("WECHAT", "微信支付", PaymentChannelDirection.BOTH, "wechat", 100, 500000, 20),
                channel("UNIONPAY", "银联云闪付", PaymentChannelDirection.RECHARGE, "unionpay", 100, 500000, 30),
                channel("BANK", "银行卡", PaymentChannelDirection.WITHDRAW, "bank", 1000, 5000000, 40)
        );
        channelRepository.saveAll(channels);
        log.info("已初始化 {} 个支付/提现渠道", channels.size());
    }

    private PaymentChannel channel(String code, String name, PaymentChannelDirection direction,
                                   String icon, long minFen, long maxFen, int sortOrder) {
        return PaymentChannel.builder()
                .code(code)
                .name(name)
                .direction(direction)
                .icon(icon)
                .enabled(true)
                .minFen(minFen)
                .maxFen(maxFen)
                .feeRateBps(0)
                .sortOrder(sortOrder)
                .build();
    }
}