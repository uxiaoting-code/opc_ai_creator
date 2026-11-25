package com.opc.server;

import com.opc.server.ai.AiProvider;
import com.opc.server.ai.AiProviderRouter;
import com.opc.server.ai.AiTaskRequest;
import com.opc.server.ai.AiTaskResult;
import com.opc.server.ai.ProgressListener;
import com.opc.server.ai.ProviderNames;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.harness.AsyncProviderPoller;
import com.opc.server.harness.HarnessProperties;
import com.opc.server.harness.TaskStateService;
import com.opc.server.repository.AiTaskRepository;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Pageable;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AsyncProviderPollerTest {

    @Test
    void strictRouteFailsWhenRealProviderIsNotRegistered() {
        AiProviderRouter router = new AiProviderRouter(List.of());
        assertThat(router.routeStrict(ProviderNames.VOLCENGINE_VIDEO)).isEmpty();
    }

    @Test
    void pollsRunningProviderTaskAndMarksSuccess() {
        AiTaskRepository repository = mock(AiTaskRepository.class);
        TaskStateService stateService = mock(TaskStateService.class);
        HarnessProperties properties = new HarnessProperties();
        properties.setAsyncPollBatchSize(10);

        AiTask task = AiTask.builder()
                .taskNo("task-async-1")
                .status(TaskStatus.RUNNING)
                .provider(ProviderNames.VOLCENGINE_VIDEO)
                .providerTaskId("provider-job-1")
                .deleted(false)
                .build();
        task.setId(7L);

        AiProvider provider = new AiProvider() {
            @Override
            public String getName() {
                return ProviderNames.VOLCENGINE_VIDEO;
            }

            @Override
            public AiTaskResult submit(AiTaskRequest request, ProgressListener listener) {
                return AiTaskResult.fail("not used");
            }

            @Override
            public AiTaskResult query(String providerTaskId) {
                return AiTaskResult.ok(
                        providerTaskId,
                        "https://cdn.example/video.mp4",
                        null,
                        "{}",
                        10L);
            }
        };

        AiProviderRouter router = new AiProviderRouter(List.of(provider));
        AsyncProviderPoller poller = new AsyncProviderPoller(repository, router, stateService, properties);

        when(repository.findRunningAsyncTasks(eq(TaskStatus.RUNNING), any(Pageable.class)))
                .thenReturn(List.of(task));

        poller.pollProviderTasks();

        verify(stateService).markSuccess(eq(7L), any(AiTaskResult.class));
    }
}