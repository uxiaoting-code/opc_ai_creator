package com.opc.server.controller;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.TaskResponse;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.harness.HarnessService;
import com.opc.server.security.UserContext;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.stream.Collectors;

/**
 * Harness 任务接口 —— 前端「我的任务列表」与「任务详情」两个页面用它。
 *
 * <p>返回分页结构（{@code PageResult}）而不是纯数组：
 * 任务列表会持续增长，翻页是刚需。
 * 前端 {@code TaskProvider} 会按 {@code PageResult} 解析。
 */
@RestController
@RequestMapping("/api/tasks")
public class TaskController {

    private final HarnessService harnessService;

    public TaskController(HarnessService harnessService) {
        this.harnessService = harnessService;
    }

    /**
     * 我的任务列表。
     *
     * @param status 状态筛选：QUEUED / RUNNING / SUCCESS / FAILED / CANCELED，
     *               不传表示全部。前端五个筛选 Tab 共用这一个接口。
     */
    @GetMapping
    public Result<PageResult<TaskResponse>> list(
            @RequestParam(required = false) TaskStatus status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {

        Page<AiTask> result = harnessService.listTasks(
                UserContext.require(), status, page, pageSize);

        return Result.success(PageResult.from(result, TaskResponse::from));
    }

    /**
     * 各状态任务数量，用于筛选 Tab 上的角标。
     *
     * <p>单独一个接口而不是塞进列表响应：切 Tab 时只要刷新角标，
     * 不需要把整个列表重新拉一遍。
     */
    @GetMapping("/stats")
    public Result<Map<String, Long>> stats() {
        Map<String, Long> stats = harnessService.countByStatus(UserContext.require())
                .entrySet().stream()
                .collect(Collectors.toMap(
                        e -> e.getKey().name(),
                        Map.Entry::getValue));
        return Result.success(stats);
    }

    /** 任务详情。前端「任务详情页」靠它做轮询。 */
    @GetMapping("/{id}")
    public Result<TaskResponse> detail(@PathVariable Long id) {
        AiTask task = harnessService.getTask(UserContext.require(), id);
        return Result.success(TaskResponse.from(task));
    }

    /**
     * 失败重试。
     *
     * <p>返回更新后的任务（状态已回到 QUEUED），前端据此立即刷新卡片，
     * 不用等下一次轮询。
     */
    @PostMapping("/{id}/retry")
    public Result<TaskResponse> retry(@PathVariable Long id) {
        AiTask task = harnessService.retryTask(UserContext.require(), id);
        return Result.success(TaskResponse.from(task), "已重新排队");
    }

    /** 取消排队中的任务。 */
    @PostMapping("/{id}/cancel")
    public Result<TaskResponse> cancel(@PathVariable Long id) {
        AiTask task = harnessService.cancelTask(UserContext.require(), id);
        return Result.success(TaskResponse.from(task), "任务已取消");
    }
}
