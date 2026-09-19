package com.opc.server.ai;

/**
 * 调用 AI 服务商的统一返回。
 *
 * @param success        是否成功
 * @param providerTaskId 服务商侧的任务 ID。
 *                       同步服务商（如 Mock）返回 null；
 *                       异步服务商返回它自己的 ID，Harness 之后靠它回查进度。
 * @param resultUrl      生成结果的 URL（图片或视频）
 * @param thumbnailUrl   缩略图 URL，可为 null（前端会回退用 resultUrl）
 * @param resultJson     附加信息（多图结果、视频元信息等）的 JSON 字符串
 * @param errorMessage   失败原因，直接展示给用户
 * @param elapsedMs      耗时（毫秒）
 */
public record AiTaskResult(
        boolean success,
        String providerTaskId,
        String resultUrl,
        String thumbnailUrl,
        String resultJson,
        String errorMessage,
        long elapsedMs
) {

    public static AiTaskResult ok(String resultUrl, String thumbnailUrl, long elapsedMs) {
        return new AiTaskResult(true, null, resultUrl, thumbnailUrl, null, null, elapsedMs);
    }

    /**
     * 同步服务商带附加信息的结果。
     *
     * <p>providerTaskId 留空 —— 同步服务商一次调用就出结果，
     * 不存在「稍后回查」这回事。
     */
    public static AiTaskResult ok(String resultUrl, String thumbnailUrl,
                                  String resultJson, long elapsedMs) {
        return new AiTaskResult(true, null, resultUrl, thumbnailUrl,
                resultJson, null, elapsedMs);
    }

    public static AiTaskResult ok(String providerTaskId, String resultUrl,
                                  String thumbnailUrl, String resultJson, long elapsedMs) {
        return new AiTaskResult(true, providerTaskId, resultUrl, thumbnailUrl,
                resultJson, null, elapsedMs);
    }

    public static AiTaskResult fail(String errorMessage) {
        return new AiTaskResult(false, null, null, null, null, errorMessage, 0L);
    }

    public static AiTaskResult fail(String errorMessage, long elapsedMs) {
        return new AiTaskResult(false, null, null, null, null, errorMessage, elapsedMs);
    }

    /**
     * 服务商是否接受异步执行。
     *
     * <p>返回 true 说明这次 submit 只是「提交」，
     * 真正结果要之后靠 {@link AiProvider#query(String)} 回查。
     * Mock 是同步的，所以永远返回 false。
     */
    public boolean isAsync() {
        return success && providerTaskId != null && resultUrl == null;
    }
}
