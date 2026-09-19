package com.opc.server.controller;

import com.opc.server.common.Result;
import com.opc.server.dto.TaskResponse;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.enums.TaskType;
import com.opc.server.harness.HarnessService;
import com.opc.server.security.UserContext;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 创作接口 —— 前端「文生图」「图生视频」两个创作页用它提交任务。
 *
 * <p>两个接口的入参结构完全一样，只是任务类型固定。
 * 拆成两个路径而不是一个 {@code /api/creation} 加 type 参数，
 * 是为了让前端调用处语义清晰，也方便以后给某一类单独加限流或字段。
 *
 * <p><b>返回的是任务对象，不是生成结果</b>：AI 生成是异步的，
 * 接口立刻返回一个 QUEUED 状态的任务，前端跳转到任务详情页轮询进度。
 * 这一点很重要 —— 不能让 HTTP 请求阻塞几十秒等图片生成完。
 */
@RestController
@RequestMapping("/api/creation")
public class CreationController {

    private final HarnessService harnessService;

    public CreationController(HarnessService harnessService) {
        this.harnessService = harnessService;
    }

    /** 文生图：提交后返回排队中的任务。 */
    @PostMapping("/text-to-image")
    public Result<TaskResponse> textToImage(@Valid @RequestBody CreationRequest request) {
        return createTask(request, TaskType.TEXT_TO_IMAGE);
    }

    /** 图生视频：必须带首帧参考图。 */
    @PostMapping("/image-to-video")
    public Result<TaskResponse> imageToVideo(@Valid @RequestBody CreationRequest request) {
        return createTask(request, TaskType.IMAGE_TO_VIDEO);
    }

    private Result<TaskResponse> createTask(CreationRequest request, TaskType type) {
        AiTask task = harnessService.createTask(
                UserContext.require(),
                type,
                request.skillId(),
                request.prompt(),
                request.negativePrompt(),
                request.refImageUrl());

        return Result.success(TaskResponse.from(task), "任务已提交，正在排队");
    }
}
