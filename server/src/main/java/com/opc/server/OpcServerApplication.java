package com.opc.server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * OPC AI 多模态创作平台 · 后端入口。
 *
 * <p>模块划分：
 * <ul>
 *   <li>{@code harness}   —— 任务调度系统：排队 → 生成中 → 成功/失败，支持重试</li>
 *   <li>{@code ai}        —— AI 服务商抽象（MCP 思想），Mock 实现 + 真实服务商接入位</li>
 *   <li>{@code entity/repository/service/controller} —— 标准分层</li>
 *   <li>{@code common}    —— 统一响应体、全局异常、错误码</li>
 * </ul>
 *
 * <p>{@code @EnableScheduling} 是 Harness 的心脏：调度器靠 {@code @Scheduled}
 * 定时轮询数据库里的排队任务。
 */
@SpringBootApplication
@EnableScheduling
@EnableAsync
public class OpcServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(OpcServerApplication.class, args);
    }
}
