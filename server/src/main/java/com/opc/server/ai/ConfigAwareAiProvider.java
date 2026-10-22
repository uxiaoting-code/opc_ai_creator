package com.opc.server.ai;

/**
 * 支持「每次调用带配置」的 AI 服务商。
 *
 * <p>配置化 HTTP 服务商不能像 Mock 那样靠 {@code @Value} 固定参数，
 * 必须由调用方把该次调用的配置传进来。
 */
public interface ConfigAwareAiProvider extends AiProvider {

    /** 按指定配置执行一次生成。 */
    AiTaskResult submit(ProviderRuntimeConfig config,
                        AiTaskRequest request,
                        ProgressListener listener);

    /** 按指定配置做一次连通性测试。 */
    ProviderTestResult test(ProviderRuntimeConfig config, String prompt);
}
