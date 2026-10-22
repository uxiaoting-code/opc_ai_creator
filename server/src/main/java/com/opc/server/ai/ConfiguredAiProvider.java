package com.opc.server.ai;

/**
 * 把一个 {@link ConfigAwareAiProvider} 和一份配置绑定成一个普通的
 * {@link AiProvider}，这样 Harness 无需知道「配置」的存在。
 */
public class ConfiguredAiProvider implements AiProvider {

    private final ConfigAwareAiProvider delegate;
    private final ProviderRuntimeConfig config;

    public ConfiguredAiProvider(ConfigAwareAiProvider delegate, ProviderRuntimeConfig config) {
        this.delegate = delegate;
        this.config = config;
    }

    @Override
    public String getName() {
        return delegate.getName();
    }

    @Override
    public boolean isAvailable() {
        return delegate.isAvailable();
    }

    @Override
    public AiTaskResult submit(AiTaskRequest request, ProgressListener listener) {
        return delegate.submit(config, request, listener);
    }

    /** 供管理端连通性测试使用。 */
    public ProviderTestResult test(String prompt) {
        return delegate.test(config, prompt);
    }
}
