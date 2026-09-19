package com.opc.server.ai;

/**
 * 生成进度回调。
 *
 * <p>Provider 在生成过程中回调它，Harness 再把进度写进 {@code t_ai_task.progress}，
 * 前端任务列表就能看到进度条在动 —— 这是答辩演示时最能体现
 * 「任务在真实调度」的一个细节。
 *
 * <p>用函数式接口而不是让 Provider 直接操作数据库，
 * 是为了让 AI 层保持对持久化的无知。
 */
@FunctionalInterface
public interface ProgressListener {

    /** 不关心进度的场景直接用这个，省去判空。 */
    ProgressListener NOOP = percent -> {
    };

    /**
     * @param percent 进度百分比 0-100
     */
    void onProgress(int percent);
}
