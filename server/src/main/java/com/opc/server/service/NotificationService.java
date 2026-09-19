package com.opc.server.service;

import com.opc.server.dto.NotificationResponse;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.repository.AiTaskRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;

/**
 * 消息通知服务。
 *
 * <p><b>通知是从任务表派生的，没有独立的通知表。</b>
 *
 * <p>这样做的理由：消息内容在任务进入终态那一刻就完全确定了
 * （成功/失败/取消 + 提示词摘要），单独存一张表只是把同样的信息复制一遍，
 * 却引入了「任务改了通知没跟着改」的数据一致性问题。
 * 派生的方式永远和任务状态一致，也不会有冗余数据。
 *
 * <p>代价：没有持久化的「已读」状态，只能用「24 小时内算未读」近似。
 * 要做真正带已读回执的消息中心时，加一张 {@code t_notification} 表，
 * 把这里的实现换掉即可 —— 前端拿到的字段结构不变。
 */
@Service
public class NotificationService {

    /** 进入终态的任务才有通知价值。 */
    private static final EnumSet<TaskStatus> FINISHED_STATUSES =
            EnumSet.of(TaskStatus.SUCCESS, TaskStatus.FAILED, TaskStatus.CANCELED);

    /** 未读判定窗口（小时）。 */
    private static final int UNREAD_WINDOW_HOURS = 24;

    private final AiTaskRepository taskRepository;

    public NotificationService(AiTaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    /** 按时间倒序取最近的任务动态。 */
    @Transactional(readOnly = true)
    public List<NotificationResponse> list(Long userId, int limit) {
        List<AiTask> tasks = taskRepository.findRecentFinished(
                userId, FINISHED_STATUSES, PageRequest.of(0, Math.max(1, limit)));

        return tasks.stream().map(NotificationResponse::fromTask).toList();
    }

    /**
     * 未读数。
     *
     * <p>只取最近一批任务来数，而不是把全部历史都查出来 ——
     * 首页只要一个红点数字，没必要为此扫描整张表。
     */
    @Transactional(readOnly = true)
    public int unreadCount(Long userId) {
        List<AiTask> recent = taskRepository.findRecentFinished(
                userId, FINISHED_STATUSES, PageRequest.of(0, 50));

        LocalDateTime threshold = LocalDateTime.now().minusHours(UNREAD_WINDOW_HOURS);
        return (int) recent.stream()
                .filter(task -> {
                    LocalDateTime happenedAt = task.getFinishAt() == null
                            ? task.getCreatedAt() : task.getFinishAt();
                    return happenedAt != null && happenedAt.isAfter(threshold);
                })
                .count();
    }
}
