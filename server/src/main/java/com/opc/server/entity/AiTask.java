package com.opc.server.entity;

import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.entity.enums.TaskType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * AI 生成任务，对应 {@code t_ai_task}。**Harness 调度系统的核心实体。**
 *
 * <p>状态流转由本类的方法控制，外部不允许直接 setStatus，
 * 这样状态机的合法性只有一处实现：
 * <pre>
 *   QUEUED ──markRunning()──▶ RUNNING ──markSuccess()──▶ SUCCESS
 *     │                          └────markFailed()───▶ FAILED ──requeue()──▶ QUEUED
 *     └──markCanceled()──▶ CANCELED
 * </pre>
 *
 * <p>另一个关键点：创建任务时会把 Skill 的参数<b>快照</b>进 {@code paramsJson}，
 * 并且把拼好的最终提示词存进 {@code prompt}。这样即使之后运营改了线路配置，
 * 历史任务回看时仍然是当时真实的生成参数。
 */
@Entity
@Table(name = "t_ai_task")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiTask extends BaseEntity {

    /** 任务编号（UUID），对外暴露用，避免用户枚举自增 ID */
    @Column(name = "task_no", nullable = false, length = 64, unique = true)
    private String taskNo;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private TaskType type;

    @Column(name = "skill_id")
    private Long skillId;

    // -----------------------------------------------------------------------
    // 输入参数（创建时快照）
    // -----------------------------------------------------------------------

    /** 最终的提示词（已经拼上线路的风格前缀/后缀） */
    @Column(name = "prompt", length = 2000)
    private String prompt;

    @Column(name = "negative_prompt", length = 1000)
    private String negativePrompt;

    /** 参考图 / 首帧图地址（图生视频必填） */
    @Column(name = "ref_image_url", length = 255)
    private String refImageUrl;

    /** Skill 完整参数快照（JSON 字符串） */
    @Column(name = "params_json", length = 4000)
    private String paramsJson;

    // -----------------------------------------------------------------------
    // Harness 调度状态
    // -----------------------------------------------------------------------

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private TaskStatus status = TaskStatus.QUEUED;

    /** 进度 0-100，由 AiProvider 通过回调上报 */
    @Column(name = "progress", nullable = false)
    @Builder.Default
    private Integer progress = 0;

    @Column(name = "queue_at")
    private LocalDateTime queueAt;

    @Column(name = "start_at")
    private LocalDateTime startAt;

    @Column(name = "finish_at")
    private LocalDateTime finishAt;

    /** 总耗时（毫秒） */
    @Column(name = "duration_ms")
    private Long durationMs;

    // -----------------------------------------------------------------------
    // 结果
    // -----------------------------------------------------------------------

    @Column(name = "result_url", length = 255)
    private String resultUrl;

    @Column(name = "result_thumb", length = 255)
    private String resultThumb;

    @Column(name = "result_json", length = 4000)
    private String resultJson;

    /** 失败原因，直接展示给用户 */
    @Column(name = "error_msg", length = 1000)
    private String errorMsg;

    // -----------------------------------------------------------------------
    // 服务商解耦（MCP 思想）
    // -----------------------------------------------------------------------

    /** 实际执行的服务商标识，任务创建时从 Skill 快照过来 */
    @Column(name = "provider", length = 50)
    private String provider;

    /** 服务商侧的任务 ID，用于回查异步任务 */
    @Column(name = "provider_task_id", length = 128)
    private String providerTaskId;

    // -----------------------------------------------------------------------
    // 重试
    // -----------------------------------------------------------------------

    @Column(name = "retry_count", nullable = false)
    @Builder.Default
    private Integer retryCount = 0;

    @Column(name = "max_retry", nullable = false)
    @Builder.Default
    private Integer maxRetry = 3;

    /** 逻辑删除（DB 列是 TINYINT，Java 侧用布尔语义以支持 DeletedFalse 派生查询） */
    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;

    // -----------------------------------------------------------------------
    // 非持久化字段：联表带出的展示信息，避免前端再查一次
    // -----------------------------------------------------------------------

    /** 线路名称，由 Service 填充 */
    @Transient
    private String skillName;

    /** 线路编码，由 Service 填充 */
    @Transient
    private String skillCode;

    // =========================================================================
    // 状态流转：所有状态变更都必须走这里
    // =========================================================================

    /**
     * 调度器抢到任务，进入生成中。
     *
     * <p>注意：真正防重复消费的是数据库层的原子 UPDATE
     * （{@code WHERE id=? AND status='QUEUED'}），不是这个 Java 方法。
     */
    public void markRunning() {
        this.status = TaskStatus.RUNNING;
        this.startAt = LocalDateTime.now();
        this.progress = 0;
        this.errorMsg = null;
    }

    /** 生成成功。 */
    public void markSuccess(String resultUrl, String resultThumb, String resultJson) {
        this.status = TaskStatus.SUCCESS;
        this.resultUrl = resultUrl;
        this.resultThumb = resultThumb;
        this.resultJson = resultJson;
        this.progress = 100;
        this.finishAt = LocalDateTime.now();
        this.errorMsg = null;
        this.durationMs = computeDuration();
    }

    /** 生成失败，记录原因。 */
    public void markFailed(String errorMessage) {
        this.status = TaskStatus.FAILED;
        this.errorMsg = errorMessage;
        this.finishAt = LocalDateTime.now();
        this.durationMs = computeDuration();
    }

    /** 用户主动取消（只允许取消还在排队的任务）。 */
    public void markCanceled() {
        this.status = TaskStatus.CANCELED;
        this.finishAt = LocalDateTime.now();
        this.durationMs = computeDuration();
    }

    /**
     * 失败重试：回到排队状态，重新入队。
     *
     * <p>会把 {@code queueAt} 刷新成当前时间并清掉上一次的执行痕迹，
     * 这样重试的任务在队列里是「新」的，也会重新计时。
     */
    public void requeue() {
        this.status = TaskStatus.QUEUED;
        this.retryCount = (retryCount == null ? 0 : retryCount) + 1;
        this.queueAt = LocalDateTime.now();
        this.startAt = null;
        this.finishAt = null;
        this.durationMs = null;
        this.progress = 0;
        this.errorMsg = null;
        this.providerTaskId = null;
    }

    /** 进度上报（0-100 夹紧，防止服务商返回越界值把前端进度条画崩）。 */
    public void updateProgress(int value) {
        this.progress = Math.max(0, Math.min(100, value));
    }

    // =========================================================================
    // 判定方法
    // =========================================================================

    /** 还能不能重试：失败状态 + 没超过最大重试次数。 */
    public boolean canRetry() {
        return status == TaskStatus.FAILED
                && (retryCount == null ? 0 : retryCount) < (maxRetry == null ? 0 : maxRetry);
    }

    /** 还能不能取消：只有排队中的任务能取消，已经开始生成的不让取消。 */
    public boolean canCancel() {
        return status == TaskStatus.QUEUED;
    }

    /** 是否已结束（前端据此决定还要不要继续轮询）。 */
    public boolean isFinished() {
        return status != null && status.isTerminal();
    }

    private Long computeDuration() {
        if (startAt == null) {
            return null;
        }
        return Duration.between(startAt, LocalDateTime.now()).toMillis();
    }
}
