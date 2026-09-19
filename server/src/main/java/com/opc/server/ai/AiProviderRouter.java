package com.opc.server.ai;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 服务商路由器：按线路配置的 {@code provider} 字段选择合适的实现。
 *
 * <p>Spring 启动时把所有 {@link AiProvider} 实现类注入进来，
 * 这里按 {@link AiProvider#getName()} 建索引。
 *
 * <p><b>刻意不用 {@code Map<String, AiProvider>} 的按 bean 名注入</b>，
 * 而是注入 {@code List} 后按 {@code getName()} 建表 ——
 * 这样服务商标识不受 Spring bean 命名影响，
 * 实现类改个类名不会导致路由失效。
 */
@Component
public class AiProviderRouter {

    private static final Logger log = LoggerFactory.getLogger(AiProviderRouter.class);

    /** provider 标识 → 实现。保持插入顺序，便于日志排查。 */
    private final Map<String, AiProvider> providerMap = new LinkedHashMap<>();

    public AiProviderRouter(List<AiProvider> providers) {
        for (AiProvider provider : providers) {
            AiProvider previous = providerMap.put(provider.getName(), provider);
            if (previous != null) {
                log.warn("服务商标识重复：{}，{} 覆盖了 {}",
                        provider.getName(),
                        provider.getClass().getSimpleName(),
                        previous.getClass().getSimpleName());
            }
        }
        log.info("已注册 AI 服务商：{}", providerMap.keySet());
    }

    /**
     * 按标识路由。
     *
     * <p>找不到时<b>降级到 Mock 而不是直接失败</b> ——
     * 课设演示时如果某个真实服务商的密钥没配好，
     * 整条链路仍然能跑通，不会当场卡住。降级会打 warn 日志。
     *
     * @param providerName 线路配置的服务商标识，可为 null
     */
    public AiProvider route(String providerName) {
        if (providerName != null) {
            AiProvider provider = providerMap.get(providerName);
            if (provider != null && provider.isAvailable()) {
                return provider;
            }
            if (provider != null) {
                log.warn("服务商 {} 当前不可用，降级到 {}", providerName, ProviderNames.MOCK);
            } else {
                log.warn("未注册的服务商 {}，降级到 {}", providerName, ProviderNames.MOCK);
            }
        }

        AiProvider fallback = providerMap.get(ProviderNames.MOCK);
        if (fallback != null) {
            return fallback;
        }

        // 连 mock 都没有说明 Spring 装配出了问题，属于启动期配置错误
        throw new IllegalStateException("没有可用的 AI 服务商实现，至少需要注册一个 " + ProviderNames.MOCK);
    }

    /** 已注册的服务商标识集合，设置页可以展示出来。 */
    public Set<String> availableProviders() {
        return providerMap.keySet();
    }

    public boolean supports(String providerName) {
        return providerMap.containsKey(providerName);
    }
}
