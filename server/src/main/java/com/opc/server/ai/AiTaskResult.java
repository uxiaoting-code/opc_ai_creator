package com.opc.server.ai;

/**
 * 调用 AI 服务商的统一返回。
 *
 * @param success        是否成功
 * @param providerTaskId 服务商侧的任务 ID
 * @param resultUrl      生成结果的 URL（图片或视频）
 * @param thumbnailUrl   缩略图 URL，可为 null
 * @param resultJson     附加信息（多图结果、视频元信息等）的 JSON 字符串
 * @param errorMessage   失败原因
 * @param elapsedMs      耗时（毫秒）
 * @param progress       异步任务进度，0-99；同步结果为 null
 */
public record AiTaskResult(
        boolean success,
        String providerTaskId,
        String resultUrl,
        String thumbnailUrl,
        String resultJson,
        String errorMessage,
        long elapsedMs,
        Integer progress
) {

    public static AiTaskResult ok(String resultUrl, String thumbnailUrl, long elapsedMs) {
        return new AiTaskResult(true, null, resultUrl, thumbnailUrl, null, null, elapsedMs, null);
    }

    public static AiTaskResult ok(String resultUrl, String thumbnailUrl,
                                  String resultJson, long elapsedMs) {
        return new AiTaskResult(true, null, resultUrl, thumbnailUrl,
                resultJson, null, elapsedMs, null);
    }

    public static AiTaskResult ok(String providerTaskId, String resultUrl,
                                  String thumbnailUrl, String resultJson, long elapsedMs) {
        return new AiTaskResult(true, providerTaskId, resultUrl, thumbnailUrl,
                resultJson, null, elapsedMs, null);
    }

    /** 异步任务已提交，结果尚未就绪。 */
    public static AiTaskResult async(String providerTaskId,
                                     Integer progress,
                                     String resultJson,
                                     long elapsedMs) {
        return new AiTaskResult(true, providerTaskId, null, null,
                resultJson, null, elapsedMs,
                progress == null ? 0 : Math.max(0, Math.min(99, progress)));
    }

    public static AiTaskResult fail(String errorMessage) {
        return new AiTaskResult(false, null, null, null, null, errorMessage, 0L, null);
    }

    public static AiTaskResult fail(String errorMessage, long elapsedMs) {
        return new AiTaskResult(false, null, null, null, null, errorMessage, elapsedMs, null);
    }

    /** 服务商是否处于“已提交、等待回查”的异步状态。 */
    public boolean isAsync() {
        return success && providerTaskId != null && resultUrl == null;
    }
}