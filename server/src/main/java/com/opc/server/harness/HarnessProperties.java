package com.opc.server.harness;

import com.opc.server.entity.enums.TaskType;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Harness 调度参数，对应 {@code application.yml} 里的 {@code opc.harness.*}。
 *
 * <p>全部可配是有意为之：课设答辩时想把生成调快一点、或者想演示
 * 「任务积压排队」的效果，改配置即可，不用改代码重新编译。
 */
@Component
@ConfigurationProperties(prefix = "opc.harness")
public class HarnessProperties {

    /** 轮询间隔（毫秒）。越小越实时，但数据库压力越大。 */
    private long pollIntervalMs = 3000;

    /** 每轮最多捞几个任务。 */
    private int batchSize = 5;

    /** 同时执行的任务数下限。 */
    private int corePoolSize = 2;

    /** 同时执行的任务数上限。 */
    private int maxPoolSize = 4;

    /** 等待队列容量。满了之后新任务留在数据库排队，不会丢。 */
    private int queueCapacity = 200;

    /** 新任务默认最大重试次数。 */
    private int defaultMaxRetry = 3;

    /** 每个文生图任务消耗的算力点。 */
    private int creditsPerTask = 10;

    /**
     * 每个图生视频任务消耗的算力点。
     *
     * <p>比文生图贵是有理由的：视频要逐帧生成再编码，算力开销远高于出单张图。
     * 这个价差也让「算力点」这个概念在演示时有实际意义 ——
     * 用户能直观感到不同创作类型的成本不一样。
     */
    private int creditsPerVideoTask = 15;

    /** 生成超时（秒）。超时视为任务失败，可重试。 */
    private long taskTimeoutSeconds = 300;

    public long getPollIntervalMs() {
        return pollIntervalMs;
    }

    public void setPollIntervalMs(long pollIntervalMs) {
        this.pollIntervalMs = pollIntervalMs;
    }

    public int getBatchSize() {
        return batchSize;
    }

    public void setBatchSize(int batchSize) {
        this.batchSize = batchSize;
    }

    public int getCorePoolSize() {
        return corePoolSize;
    }

    public void setCorePoolSize(int corePoolSize) {
        this.corePoolSize = corePoolSize;
    }

    public int getMaxPoolSize() {
        return maxPoolSize;
    }

    public void setMaxPoolSize(int maxPoolSize) {
        this.maxPoolSize = maxPoolSize;
    }

    public int getQueueCapacity() {
        return queueCapacity;
    }

    public void setQueueCapacity(int queueCapacity) {
        this.queueCapacity = queueCapacity;
    }

    public int getDefaultMaxRetry() {
        return defaultMaxRetry;
    }

    public void setDefaultMaxRetry(int defaultMaxRetry) {
        this.defaultMaxRetry = defaultMaxRetry;
    }

    public int getCreditsPerTask() {
        return creditsPerTask;
    }

    public void setCreditsPerTask(int creditsPerTask) {
        this.creditsPerTask = creditsPerTask;
    }

    public int getCreditsPerVideoTask() {
        return creditsPerVideoTask;
    }

    public void setCreditsPerVideoTask(int creditsPerVideoTask) {
        this.creditsPerVideoTask = creditsPerVideoTask;
    }

    /**
     * 按任务类型取算力点单价。
     *
     * <p>规则集中在这里，而不是散在调用方写三目运算 ——
     * 以后加第三种创作类型（比如图生图）时只需要改这一个方法。
     * 类型为 null 时按文生图计价（便宜的那档），宁可少扣也不要误扣。
     */
    public int creditsFor(TaskType type) {
        return type == TaskType.IMAGE_TO_VIDEO ? creditsPerVideoTask : creditsPerTask;
    }

    public long getTaskTimeoutSeconds() {
        return taskTimeoutSeconds;
    }

    public void setTaskTimeoutSeconds(long taskTimeoutSeconds) {
        this.taskTimeoutSeconds = taskTimeoutSeconds;
    }
}
