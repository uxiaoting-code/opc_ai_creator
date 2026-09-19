package com.opc.server.dto;

import com.opc.server.entity.AiTask;

import java.time.LocalDateTime;

/**
 * 任务响应。
 *
 * <p>除了实体本身的字段，额外补了几个<b>前端算起来麻烦、后端顺手就能给</b>的派生字段：
 * {@code statusLabel}（状态中文名）、{@code canRetry} / {@code canCancel}（按钮是否可点）。
 * 这样前端不用把状态机规则再实现一遍 —— 规则只有后端一份，不会两端不一致。
 */
public record TaskResponse(
        Long id,
        String taskNo,
        String type,
        String typeLabel,

        Long skillId,
        String skillName,
        String skillCode,

        String prompt,
        String negativePrompt,
        String refImageUrl,

        String status,
        String statusLabel,
        Integer progress,

        String resultUrl,
        String resultThumb,
        String errorMsg,

        String provider,
        String providerTaskId,

        Integer retryCount,
        Integer maxRetry,
        Boolean canRetry,
        Boolean canCancel,
        Boolean finished,

        LocalDateTime queueAt,
        LocalDateTime startAt,
        LocalDateTime finishAt,
        Long durationMs,
        LocalDateTime createdAt
) {

    public static TaskResponse from(AiTask task) {
        if (task == null) {
            return null;
        }
        return new TaskResponse(
                task.getId(),
                task.getTaskNo(),
                task.getType() == null ? null : task.getType().name(),
                task.getType() == null ? null : task.getType().getLabel(),
                task.getSkillId(),
                task.getSkillName(),
                task.getSkillCode(),
                task.getPrompt(),
                task.getNegativePrompt(),
                task.getRefImageUrl(),
                task.getStatus() == null ? null : task.getStatus().name(),
                task.getStatus() == null ? null : task.getStatus().getLabel(),
                task.getProgress(),
                task.getResultUrl(),
                task.getResultThumb(),
                task.getErrorMsg(),
                task.getProvider(),
                task.getProviderTaskId(),
                task.getRetryCount(),
                task.getMaxRetry(),
                task.canRetry(),
                task.canCancel(),
                task.isFinished(),
                task.getQueueAt(),
                task.getStartAt(),
                task.getFinishAt(),
                task.getDurationMs(),
                task.getCreatedAt()
        );
    }
}
