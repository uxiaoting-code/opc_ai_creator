package com.opc.server.dto;

import com.opc.server.entity.enums.TaskType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 创建生成任务的请求。
 *
 * <p>对应前端 {@code ApiEndpoints.textToImage} / {@code imageToVideo}。
 */
public record CreateTaskRequest(

        @NotNull(message = "任务类型不能为空")
        TaskType type,

        /** Skill 线路 ID，可为空（走默认参数） */
        Long skillId,

        @Size(max = 2000, message = "提示词最长 2000 个字符")
        String prompt,

        @Size(max = 1000, message = "负面提示词最长 1000 个字符")
        String negativePrompt,

        /** 参考图 / 首帧图地址，图生视频必填 */
        String refImageUrl
) {
}
