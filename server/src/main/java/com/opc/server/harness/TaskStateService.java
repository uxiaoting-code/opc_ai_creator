package com.opc.server.harness;

import com.opc.server.ai.AiTaskResult;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.Work;
import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.repository.AiTaskRepository;
import com.opc.server.repository.WorkRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 任务状态的持久化操作。<b>所有写库动作集中在这里。</b>
 *
 * <p>为什么不直接写在 {@link HarnessService} 里：Spring 的 {@code @Transactional}
 * 靠代理生效，<b>同一个 Bean 内部的方法自调用不会走代理</b>，
 * 事务注解会静默失效 —— 这是最容易踩的坑之一。
 * 把写操作单独抽成一个 Bean，调用必然跨 Bean，代理才会生效。
 */
@Service
public class TaskStateService {

    private static final Logger log = LoggerFactory.getLogger(TaskStateService.class);

    private final AiTaskRepository taskRepository;
    private final WorkRepository workRepository;

    public TaskStateService(AiTaskRepository taskRepository, WorkRepository workRepository) {
        this.taskRepository = taskRepository;
        this.workRepository = workRepository;
    }

    /**
     * 原子抢占任务：把「排队中」改成「生成中」。
     *
     * <p>返回 false 说明被别的调度线程抢先了，调用方必须放弃这个任务 ——
     * 不能因为抢不到就报错，那是并发的正常结果。
     */
    @Transactional
    public boolean claim(Long taskId) {
        int updated = taskRepository.claim(
                taskId,
                LocalDateTime.now(),
                TaskStatus.RUNNING,
                TaskStatus.QUEUED);
        if (updated == 1) {
            log.debug("任务 {} 抢占成功，进入生成中", taskId);
            return true;
        }
        log.debug("任务 {} 抢占失败（已被其它调度线程领走）", taskId);
        return false;
    }

    /**
     * 标记成功，并同步落一条作品记录。
     *
     * <p>两件事必须在一个事务里：任务成功了却没有作品，
     * 用户在画廊里就找不到刚生成的图，属于脏数据。
     */
    @Transactional
    public void markSuccess(Long taskId, AiTaskResult result) {
        AiTask task = taskRepository.findById(taskId).orElse(null);
        if (task == null) {
            log.warn("任务 {} 不存在，无法标记成功", taskId);
            return;
        }
        if (task.getStatus() != TaskStatus.RUNNING) {
            // 比如用户在此期间取消了任务，迟到的结果直接丢弃
            log.warn("任务 {} 当前状态为 {}，忽略迟到的成功结果", taskId, task.getStatus());
            return;
        }

        task.markSuccess(result.resultUrl(), result.thumbnailUrl(), result.resultJson());
        taskRepository.save(task);

        // 同一任务重复落作品时覆盖旧记录，避免重试后画廊出现两条一样的图
        Work work = workRepository.findByTaskIdAndDeletedFalse(taskId)
                .orElseGet(() -> Work.fromTask(task, task.getSkillName(),
                        result.thumbnailUrl()));
        work.setResourceUrl(result.resultUrl());
        work.setCoverUrl(result.thumbnailUrl());
        workRepository.save(work);

        log.info("任务 {} 生成成功 url={} 耗时={}ms",
                taskId, result.resultUrl(), result.elapsedMs());
    }

    /** 标记失败，记录原因供前端展示。 */
    @Transactional
    public void markFailed(Long taskId, String errorMessage) {
        AiTask task = taskRepository.findById(taskId).orElse(null);
        if (task == null) {
            return;
        }
        if (task.getStatus() != TaskStatus.RUNNING) {
            log.warn("任务 {} 当前状态为 {}，忽略迟到的失败结果", taskId, task.getStatus());
            return;
        }

        task.markFailed(errorMessage);
        taskRepository.save(task);
        log.info("任务 {} 生成失败: {}", taskId, errorMessage);
    }

    /**
     * 更新进度。
     *
     * <p>用单条 UPDATE 而不是「查出来改再存」：进度更新很频繁，
     * 读改写会带来无谓的并发竞争，而丢一次进度更新完全无害。
     * {@code status = RUNNING} 的条件保证迟到的回调不会把已结束的任务改活。
     */
    @Transactional
    public void updateProgress(Long taskId, int percent) {
        taskRepository.updateProgress(taskId, percent, TaskStatus.RUNNING);
    }

    /**
     * 应用重启时，把上次没跑完的「生成中」任务重置回「排队中」。
     *
     * <p>不做这一步的话，进程被杀时正在生成的任务会永远停在 RUNNING，
     * 既不会失败也不会重试，用户看到的是一条永远转圈的任务。
     */
    @Transactional
    public int resetStuckTasks() {
        return taskRepository.resetStuckTasks(
                TaskStatus.QUEUED,
                TaskStatus.RUNNING,
                "服务重启，任务已重新排队");
    }
}
