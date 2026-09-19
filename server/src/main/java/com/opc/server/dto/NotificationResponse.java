package com.opc.server.dto;

import com.opc.server.entity.AiTask;

import java.time.LocalDateTime;

/**
 * 消息通知响应。
 *
 * <p>字段名与前端 {@code lib/data/models/notification_model.dart} 对齐。
 *
 * <p><b>当前实现说明：</b>通知是<b>从任务表派生</b>出来的，
 * 而不是存在独立的 {@code t_notification} 表里 —— 任务成功/失败的那一刻，
 * 消息内容就已经确定了，再存一张表属于冗余。
 *
 * <p>代价是「已读/未读」只能按时间推算（见 {@code NotificationService}），
 * 不能精确记住用户点过哪一条。要做完整的消息中心时，
 * 再加 {@code t_notification} 表并把这里换成真实查询即可，
 * 前端拿到的字段结构不用变。
 */
public record NotificationResponse(
        Long id,
        String title,
        String content,
        String type,
        Boolean isRead,
        LocalDateTime createdAt
) {

    /** 任务进入终态时生成一条消息。 */
    public static NotificationResponse fromTask(AiTask task) {
        String title;
        String content;
        String type = "TASK";

        switch (task.getStatus()) {
            case SUCCESS -> {
                title = "生成成功";
                content = "作品《%s》已生成完成，点击查看".formatted(shortPrompt(task));
            }
            case FAILED -> {
                title = "任务失败";
                String reason = task.getErrorMsg() == null ? "未知原因" : task.getErrorMsg();
                content = "《%s》生成失败：%s".formatted(shortPrompt(task), reason);
            }
            case CANCELED -> {
                title = "任务已取消";
                content = "《%s》已取消".formatted(shortPrompt(task));
            }
            default -> {
                title = "任务状态更新";
                content = "《%s》当前状态：%s".formatted(
                        shortPrompt(task), task.getStatus().getLabel());
            }
        }

        LocalDateTime happenedAt = task.getFinishAt() == null
                ? task.getCreatedAt() : task.getFinishAt();

        // 24 小时内结束的算未读，更早的当作已经被用户看过。
        // 这是派生方案的折中：没有持久化的已读状态，只能用时间近似。
        boolean unread = happenedAt != null
                && happenedAt.isAfter(LocalDateTime.now().minusHours(24));

        return new NotificationResponse(
                task.getId(),
                title,
                content,
                type,
                !unread,
                happenedAt
        );
    }

    /** 取提示词前 16 个字做标题，太长会把消息列表撑乱。 */
    private static String shortPrompt(AiTask task) {
        String prompt = task.getPrompt();
        if (prompt == null || prompt.isBlank()) {
            return "未命名作品";
        }
        String trimmed = prompt.trim();
        return trimmed.length() > 16 ? trimmed.substring(0, 16) + "…" : trimmed;
    }
}
