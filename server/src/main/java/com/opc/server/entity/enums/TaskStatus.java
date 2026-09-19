package com.opc.server.entity.enums;

/**
 * Harness 任务状态。
 *
 * <p>取值与前端 {@code AppColors} 里的状态语义色一一对应，
 * 也与 {@code docs/DATABASE.md} 的状态机图一致：
 * <pre>
 *   QUEUED ──调度器取任务──▶ RUNNING ──▶ SUCCESS
 *     │                        └──────▶ FAILED ──重试──▶ QUEUED
 *     └──用户取消──▶ CANCELED
 * </pre>
 *
 * <p>数据库里以字符串存储（{@code @Enumerated(EnumType.STRING)}），
 * 不用 ordinal —— 否则以后往中间插一个状态，历史数据全部错位。
 */
public enum TaskStatus {

    /** 排队中：已入库，等待调度器领取 */
    QUEUED("排队中"),

    /** 生成中：已被调度器抢占，正在调用 AI 服务商 */
    RUNNING("生成中"),

    /** 成功：产出可用于生成作品 */
    SUCCESS("成功"),

    /** 失败：可重试（retry_count < max_retry 时还能回到 QUEUED） */
    FAILED("失败"),

    /** 已取消：用户主动取消，终态 */
    CANCELED("已取消");

    private final String label;

    TaskStatus(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    /**
     * 是否终态。
     *
     * <p>调度器的捞取语句只查 QUEUED，所以这里主要用于判断
     * 「还能不能重试 / 取消」，避免在终态上做无意义的状态迁移。
     */
    public boolean isTerminal() {
        return this == SUCCESS || this == CANCELED || this == FAILED;
    }

    /** 成功或失败之外都算「进行中」，前端用它决定要不要继续轮询。 */
    public boolean isActive() {
        return this == QUEUED || this == RUNNING;
    }
}
