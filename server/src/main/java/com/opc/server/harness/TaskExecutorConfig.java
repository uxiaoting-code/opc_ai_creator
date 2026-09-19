package com.opc.server.harness;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.ThreadPoolExecutor;

/**
 * Harness 执行线程池。
 *
 * <p>为什么调度器不能直接同步执行任务：{@code @Scheduled} 默认只有一个线程，
 * 若在轮询方法里直接调用 AI 服务商（Mock 要 2~6 秒，真实模型更久），
 * 整个调度器就被堵死了 —— 新任务全部卡在排队，无法并发生成。
 *
 * <p>所以轮询只负责「抢占 + 投递」，真正的生成交给这个线程池并发执行。
 *
 * <p>队列满时的拒绝策略用 {@link ThreadPoolExecutor.CallerRunsPolicy}：
 * 让提交者（调度线程）自己跑。这样任务不会被丢弃，
 * 代价只是那一轮轮询变慢 —— 对课设场景是最稳妥的选择。
 */
@Configuration
public class TaskExecutorConfig {

    private static final Logger log = LoggerFactory.getLogger(TaskExecutorConfig.class);

    public static final String HARNESS_EXECUTOR = "harnessExecutor";

    @Bean(name = HARNESS_EXECUTOR)
    public ThreadPoolTaskExecutor harnessExecutor(HarnessProperties properties) {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();

        executor.setCorePoolSize(properties.getCorePoolSize());
        executor.setMaxPoolSize(properties.getMaxPoolSize());
        executor.setQueueCapacity(properties.getQueueCapacity());
        executor.setThreadNamePrefix("harness-worker-");
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());

        // 优雅停机：等在跑的任务结束再退出，避免任务永远停在「生成中」
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(30);

        executor.initialize();

        log.info("Harness 线程池初始化完成 core={} max={} queue={}",
                properties.getCorePoolSize(),
                properties.getMaxPoolSize(),
                properties.getQueueCapacity());

        return executor;
    }
}
