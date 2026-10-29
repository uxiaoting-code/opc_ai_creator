package com.opc.server.init;

import com.opc.server.entity.MarketOrder;
import com.opc.server.entity.enums.MarketOrderStatus;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.repository.MarketOrderRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/** 接单市场演示数据（M1）。 */
@Component
@Order(8)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled", havingValue = "true", matchIfMissing = true)
public class MarketOrderSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(MarketOrderSeeder.class);

    private final MarketOrderRepository marketOrderRepository;

    public MarketOrderSeeder(MarketOrderRepository marketOrderRepository) {
        this.marketOrderRepository = marketOrderRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (marketOrderRepository.count() > 0) {
            log.info("接单市场已有数据，跳过初始化");
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        List<MarketOrder> orders = List.of(
                order("MO202610290001", "春季香水商品主图套组", "花漾美妆",
                        "为一款春季香水制作 4 张商品主图，要求高级、干净、有自然光感。",
                        MediaType.IMAGE, 6800L, 12, now.plusHours(26), 20, 12,
                        List.of("1:1 方图", "纯白或奶油背景", "保留瓶身真实质感", "提交 PNG")),
                order("MO202610290002", "咖啡机 15 秒展示视频", "森屿家电",
                        "生成一段咖啡机旋转展示视频，带蒸汽和生活化场景，适合抖音竖屏。",
                        MediaType.VIDEO, 12800L, 48, now.plusHours(18), 10, 7,
                        List.of("9:16 竖屏", "15 秒左右", "镜头平稳", "包含产品正面")),
                order("MO202610290003", "跨境耳机英文口播", "GlobalTrade",
                        "根据商品卖点生成 30 秒英文口播音频，语气自然、适合电商详情页。",
                        MediaType.AUDIO, 8800L, 8, now.plusDays(2), 30, 18,
                        List.of("美式英语", "约 30 秒", "语速适中", "无背景音乐")),
                order("MO202610290004", "女装数字人讲解视频", "MUSE 女装",
                        "使用数字人口播展示新品卖点，画风亲和，适合直播间预热。",
                        MediaType.VIDEO, 15800L, 48, now.plusHours(34), 15, 9,
                        List.of("9:16 竖屏", "女性数字人", "口型自然", "时长 45 秒")),
                order("MO202610290005", "护肤详情页长图", "溪野实验室",
                        "生成一张适合详情页的商品长图，包含产品、成分和核心卖点。",
                        MediaType.IMAGE, 7800L, 12, now.plusDays(3), 25, 10,
                        List.of("3:4 比例", "清爽绿色调", "留出文字区域", "提交 JPG")),
                order("MO202610290006", "食品礼盒多语言配音", "东瀛优品",
                        "生成日语和中文两版礼盒介绍音频，语气温柔，适合短视频。",
                        MediaType.AUDIO, 5600L, 8, now.plusDays(4), 30, 10,
                        List.of("中日双语", "女声", "30 秒内", "可下载 MP3"))
        );

        marketOrderRepository.saveAll(orders);
        log.info("已初始化 {} 个接单市场订单", orders.size());
    }

    private MarketOrder order(String orderNo,
                              String title,
                              String brandName,
                              String description,
                              MediaType mediaType,
                              Long rewardFen,
                              int creditCost,
                              LocalDateTime deadlineAt,
                              int tasksTotal,
                              int tasksTaken,
                              List<String> requirements) {
        return MarketOrder.builder()
                .orderNo(orderNo)
                .title(title)
                .brandName(brandName)
                .description(description)
                .mediaType(mediaType)
                .rewardFen(rewardFen)
                .creditCost(creditCost)
                .deadlineAt(deadlineAt)
                .tasksTotal(tasksTotal)
                .tasksTaken(tasksTaken)
                .requirements(requirements)
                .status(MarketOrderStatus.OPEN)
                .build();
    }
}