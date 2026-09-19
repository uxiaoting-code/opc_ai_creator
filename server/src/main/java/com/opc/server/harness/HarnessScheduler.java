package com.opc.server.harness;

import com.opc.server.entity.AiTask;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.ThreadPoolExecutor;

/**
 * Harness 调度器 —— <b>「排队 → 生成中」这一步的实现。</b>
 *
 * <p>工作方式：定时轮询数据库里的排队任务，逐条原子抢占，
 * 抢到就投递到线程池并发执行。
 *
 * <p>为什么用「数据库轮询」而不是消息队列（RabbitMQ / Redis）：
 * 课设场景下引入 MQ 会让部署复杂度陡增，而轮询方案
 * <b>天然支持任务持久化、服务重启后不丢任务</b>，
 * 对本项目的规模完全够用。真要做大，把
 * {@link #pollAndDispatch()} 换成 MQ 消费者即可，其余代码不动。
 */
@Component
public class HarnessScheduler {

    private static final Logger log = LoggerFactory.getLogger(HarnessScheduler.class);

    private final HarnessService harnessService;
    private final TaskStateService stateService;
    private final HarnessProperties properties;
    private final ThreadPoolTaskExecutor executor;

    public HarnessScheduler(HarnessService harnessService,
                            TaskStateService stateService,
                            HarnessProperties properties,
                            @Qualifier(TaskExecutorConfig.HARNESS_EXECUTOR)
                            ThreadPoolTaskExecutor executor) {
        this.harnessService = harnessService;
        this.stateService = stateService;
        this.properties = properties;
        this.executor = executor;
    }

    // =========================================================================
    // 一、启动自愈
    // =========================================================================

    /**
     * 应用启动完成后，把上次没跑完的「生成中」任务重置回「排队中」。
     *
     * <p>不做这一步的后果：服务被强杀时正在生成的任务会永远停在 RUNNING，
     * 用户看到一条永远转圈的任务，既不会失败也没法重试。
     */
    @EventListener(ApplicationReadyEvent.class)
    public void recoverStuckTasksOnStartup() {
        try {
            int recovered = stateService.resetStuckTasks();
            if (recovered > 0) {
                log.info("启动自愈：{} 个中断的任务已重新排队", recovered);
            }
        } catch (Exception e) {
            // 自愈失败不能影响启动，否则一个脏数据就把整个服务卡住
            log.error("启动自愈失败", e);
        }
    }

    // =========================================================================
    // 二、主循环：捞任务 → 抢占 → 投递
    // =========================================================================

    /**
     * 轮询待调度任务。
     *
     * <p>{@code fixedDelay} 而不是 {@code fixedRate}：
     * 前者保证「上一轮跑完再等 N 毫秒」，不会因为某一轮处理慢而堆积重叠执行。
     */
    @Scheduled(fixedDelayString = "${opc.harness.poll-interval-ms:3000}")
    public void pollAndDispatch() {
        try {
            // 线程池队列快满时不再抢占。
            // 否则抢占后投递会被 CallerRunsPolicy 拿调度线程去跑，
            // 整个调度器就堵在这一轮上了，越堵越糟。
            if (remainingCapacity() <= 0) {
                log.debug("Harness 线程池队列已满，本轮暂停派发");
                return;
            }

            List<AiTask> candidates = harnessService.findDispatchable(properties.getBatchSize());
            if (candidates.isEmpty()) {
                return;
            }

            int dispatched = 0;
            for (AiTask task : candidates) {
                // 抢占失败说明被别的线程领走了，跳过即可，这不是错误
                if (!stateService.claim(task.getId())) {
                    continue;
                }

                Long taskId = task.getId();
                executor.execute(() -> {
                    try {
                        harnessService.executeTask(taskId);
                    } catch (Exception e) {
                        // 工作线程的异常必须自己吞掉并记录，否则会静默消失，
                        // 任务永远停在「生成中」
                        log.error("任务 {} 执行失败", taskId, e);
                        stateService.markFailed(taskId, "执行异常：" + e.getMessage());
                    }
                });
                dispatched++;
            }

            if (dispatched > 0) {
                log.info("本轮派发 {} 个任务（候选 {} 个）", dispatched, candidates.size());
            }
        } catch (Exception e) {
            // 调度线程绝不能因为一次异常就死掉 —— @Scheduled 任务抛异常后
            // 后续仍会执行，但会刷错误日志，这里兜住让日志干净些
            log.error("Harness 轮询异常", e);
        }
    }

    // =========================================================================
    // 三、超时清理
    // =========================================================================

    /**
     * 定期把卡在「生成中」太久的任务判为失败。
     *
     * <p>用「扫描式看门狗」而不是给每个任务起一个定时线程：
     * 后者在任务多的时候会创建大量线程，前者只是一条查询，代价恒定。
     */
    @Scheduled(fixedDelayString = "${opc.harness.timeout-sweep-interval-ms:30000}")
    public void sweepTimeoutTasks() {
        try {
            int failed = harnessService.failTimeoutTasks();
            if (failed > 0) {
                log.warn("超时清理：{} 个任务被判定为生成超时", failed);
            }
        } catch (Exception e) {
            log.error("超时清理异常", e);
        }
    }

    /** 线程池剩余队列容量。 */
    private int remainingCapacity() {
        ThreadPoolExecutor pool = executor.getThreadPoolExecutor();
        return pool.getQueue().remainingCapacity();
    }
}
