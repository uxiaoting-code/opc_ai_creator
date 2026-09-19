package com.opc.server.controller;

import jakarta.validation.constraints.Size;

/**
 * 创作请求体。
 *
 * <p>与 {@code CreateTaskRequest} 的区别：这里<b>没有 type 字段</b> ——
 * 类型由调用的接口路径决定（文生图 / 图生视频各一个路径），
 * 客户端传了也没用，干脆不要这个字段，避免「路径说文生图、body 说图生视频」
 * 这种自相矛盾的请求出现。
 */
public record CreationRequest(

        /** Skill 线路 ID，为空时用默认参数 */
        Long skillId,

        @Size(max = 2000, message = "提示词最长 2000 个字符")
        String prompt,

        @Size(max = 1000, message = "负面提示词最长 1000 个字符")
        String negativePrompt,

        /** 参考图 / 首帧图地址，图生视频必填 */
        String refImageUrl
) {
}
