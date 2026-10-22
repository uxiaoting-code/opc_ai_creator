package com.opc.server.init;

import com.opc.server.entity.AiProviderConfig;
import com.opc.server.repository.AiProviderConfigRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/**
 * 管理端演示数据（后端线负责的模块）。
 *
 * <p>与 {@link DataSeeder} 分开放，避免两人同时改一个文件。
 * 这里只初始化「大模型配置」页要展示的 6 条演示通道，
 * 全部使用 {@code providerImpl = "mock"}，不需要任何 API Key 就能演示。
 */
@Component
@Order(2)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled",
        havingValue = "true", matchIfMissing = true)
public class AdminCoreSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminCoreSeeder.class);

    private final AiProviderConfigRepository repository;

    public AdminCoreSeeder(AiProviderConfigRepository repository) {
        this.repository = repository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (repository.countByDeletedFalse() > 0) {
            log.info("模型配置已存在，跳过初始化");
            return;
        }

        List<AiProviderConfig> rows = List.of(
                row("TT Image 2", "字节跳动", "IMAGE", "DE-TT-oai-pro",
                        "tt-image-2", "77.28", "284.00", "TOKEN", true, 1),
                row("GEM 3.7 flash", "Google", "CHAT", "KJ-gp",
                        "gem-3.7-flash", "115.92", "428.90", "TOKEN", true, 2),
                row("即梦 3.5 Pro", "字节跳动", "VIDEO", "DE-JM-raw",
                        "jimeng-3.5-pro", "0.1932", "0.8694", "SECOND", true, 3),
                row("纳米香蕉 Pro", "Google", "IMAGE", "TX-y3",
                        "nano-banana-pro", "113.99", "421.18", "TOKEN", true, 4),
                row("海螺 语音克隆 2.8", "MiniMax", "AUDIO", "MM-voice-cn",
                        "hailuo-voice-2.8", null, null, "TOKEN", true, 5),
                row("TT Image 2.5 官转", "字节跳动", "IMAGE", "DE-TT-official",
                        "tt-image-2.5", "88.00", "312.00", "TOKEN", false, 6)
        );

        repository.saveAll(rows);
        log.info("已初始化 {} 条模型配置", rows.size());
    }

    private AiProviderConfig row(String name, String vendor, String type, String channel,
                                 String modelName, String inputPrice, String outputPrice,
                                 String priceUnit, boolean online, int sortOrder) {
        return AiProviderConfig.builder()
                .name(name)
                .vendor(vendor)
                .type(type)
                .channel(channel)
                .modelName(modelName)
                .providerImpl("mock")
                .authType("NONE")
                .requestMethod("POST")
                .requestContentType("application/json")
                .inputPrice(inputPrice == null ? null : new BigDecimal(inputPrice))
                .outputPrice(outputPrice == null ? null : new BigDecimal(outputPrice))
                .priceUnit(priceUnit)
                .timeoutSeconds(180)
                .online(online)
                .sortOrder(sortOrder)
                .deleted(false)
                .build();
    }
}
