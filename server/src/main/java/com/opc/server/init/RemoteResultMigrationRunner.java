package com.opc.server.init;

import com.opc.server.ai.AiTaskResult;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.Work;
import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.repository.AiTaskRepository;
import com.opc.server.repository.WorkRepository;
import com.opc.server.storage.GeneratedMediaLocalizer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 把历史上已经成功、但仍保存第三方临时 URL 的任务迁移成本地文件。
 *
 * <p>这是一次兜底迁移：它让修复前已经生成的图片也能重新出现在 Flutter，
 * 并避免签名 URL 过期后作品永久失效。
 */
@Component
@Order(20)
public class RemoteResultMigrationRunner implements ApplicationRunner {

    private static final Logger log =
            LoggerFactory.getLogger(RemoteResultMigrationRunner.class);

    private final AiTaskRepository taskRepository;
    private final WorkRepository workRepository;
    private final GeneratedMediaLocalizer localizer;

    public RemoteResultMigrationRunner(AiTaskRepository taskRepository,
                                       WorkRepository workRepository,
                                       GeneratedMediaLocalizer localizer) {
        this.taskRepository = taskRepository;
        this.workRepository = workRepository;
        this.localizer = localizer;
    }

    @Override
    public void run(ApplicationArguments args) {
        List<AiTask> tasks = taskRepository
                .findByStatusAndResultUrlStartingWith(TaskStatus.SUCCESS, "http");
        if (tasks.isEmpty()) {
            return;
        }

        log.info("开始迁移 {} 条第三方临时结果 URL", tasks.size());
        for (AiTask task : tasks) {
            try {
                AiTaskResult original = new AiTaskResult(
                        true,
                        task.getProviderTaskId(),
                        task.getResultUrl(),
                        task.getResultThumb(),
                        task.getResultJson(),
                        null,
                        task.getDurationMs() == null ? 0L : task.getDurationMs());
                AiTaskResult localized = localizer.localize(
                        original, task.getType(), task.getTaskNo());

                task.setResultUrl(localized.resultUrl());
                task.setResultThumb(localized.thumbnailUrl());
                taskRepository.save(task);

                workRepository.findByTaskIdAndDeletedFalse(task.getId())
                        .ifPresent(work -> {
                            work.setResourceUrl(localized.resultUrl());
                            work.setCoverUrl(localized.thumbnailUrl());
                            workRepository.save(work);
                        });
                log.info("任务 {} 历史结果迁移完成", task.getId());
            } catch (Exception e) {
                log.warn("任务 {} 历史结果迁移失败，保留原 URL：{}",
                        task.getId(), e.getMessage());
            }
        }
    }
}
