package com.opc.server.controller;

import com.opc.server.ai.AiProviderRouter;
import com.opc.server.common.Result;
import com.opc.server.harness.HarnessProperties;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 健康检查与运行时信息。
 *
 * <p>这个接口<b>不需要登录</b>（在 WebConfig 里被排除）。
 * 用途：手机连不上后端时，先在浏览器打开
 * {@code http://<局域网IP>:8080/api/health} 看看通不通 ——
 * 这一条能立刻区分「网络/防火墙问题」和「登录/业务问题」，
 * 比对着 Flutter 的报错猜要快得多。
 */
@RestController
@RequestMapping("/api")
public class HealthController {

    private final AiProviderRouter providerRouter;
    private final HarnessProperties harnessProperties;

    public HealthController(AiProviderRouter providerRouter,
                            HarnessProperties harnessProperties) {
        this.providerRouter = providerRouter;
        this.harnessProperties = harnessProperties;
    }

    /** 服务状态 + 已注册的 AI 服务商 + 当前调度参数。 */
    @GetMapping("/health")
    public Result<Map<String, Object>> health() {
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("status", "UP");
        info.put("service", "opc-server");
        info.put("providers", providerRouter.availableProviders());
        info.put("pollIntervalMs", harnessProperties.getPollIntervalMs());
        info.put("batchSize", harnessProperties.getBatchSize());
        info.put("maxConcurrentTasks", harnessProperties.getMaxPoolSize());
        info.put("creditsPerTask", harnessProperties.getCreditsPerTask());
        info.put("timestamp", System.currentTimeMillis());
        return Result.success(info);
    }
}
