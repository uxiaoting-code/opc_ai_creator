package com.opc.server.harness;

import com.opc.server.ai.AiProvider;
import com.opc.server.ai.AiProviderRouter;
import com.opc.server.ai.AiTaskResult;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.repository.AiTaskRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Polls provider-side tasks submitted by an asynchronous provider.
 * Existing TaskStateService state transitions remain the only persistence path.
 */
@Component
public class AsyncProviderPoller {

    private static final Logger log = LoggerFactory.getLogger(AsyncProviderPoller.class);

    private final AiTaskRepository taskRepository;
    private final AiProviderRouter providerRouter;
    private final TaskStateService stateService;
    private final HarnessProperties properties;

    public AsyncProviderPoller(AiTaskRepository taskRepository,
                               AiProviderRouter providerRouter,
                               TaskStateService stateService,
                               HarnessProperties properties) {
        this.taskRepository = taskRepository;
        this.providerRouter = providerRouter;
        this.stateService = stateService;
        this.properties = properties;
    }

    @Scheduled(fixedDelayString = "${opc.harness.async-poll-interval-ms:3000}")
    public void pollProviderTasks() {
        List<AiTask> tasks = taskRepository.findRunningAsyncTasks(
                TaskStatus.RUNNING,
                PageRequest.of(0, Math.max(1, properties.getAsyncPollBatchSize())));
        for (AiTask task : tasks) {
            try {
                AiProvider provider = providerRouter.routeStrict(task.getProvider()).orElse(null);
                if (provider == null) {
                    stateService.markFailed(task.getId(),
                            "Provider unavailable: " + task.getProvider());
                    continue;
                }
                AiTaskResult result = provider.query(task.getProviderTaskId());
                if (!result.success()) {
                    stateService.markFailed(task.getId(), result.errorMessage());
                } else if (result.resultUrl() != null && !result.resultUrl().isBlank()) {
                    stateService.markSuccess(task.getId(), result);
                } else {
                    int progress = result.progress() == null ? 50 : result.progress();
                    stateService.updateProgress(task.getId(), progress);
                }
            } catch (Exception e) {
                log.warn("Async provider poll failed taskId={} provider={}",
                        task.getId(), task.getProvider(), e);
                stateService.markFailed(task.getId(), "Provider polling failed: " + e.getMessage());
            }
        }
    }
}