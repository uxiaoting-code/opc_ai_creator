package com.opc.server.ai;

/**
 * AI 服务商标识常量。
 *
 * <p>取值要与 {@code t_skill.provider} 字段里存的值一致 ——
 * 线路配了哪个标识，就由哪个 {@link AiProvider} 实现类执行。
 *
 * <p><b>新增一个服务商的完整步骤：</b>
 * <ol>
 *   <li>写一个 {@link AiProvider} 实现类，{@link AiProvider#getName()} 返回下面的某个值；</li>
 *   <li>加 {@code @Component} 交给 Spring（{@code AiProviderRouter} 会自动发现）；</li>
 *   <li>在 {@code t_skill} 里把某条线路的 {@code provider} 改成这个值。</li>
 * </ol>
 * 全程不需要改动 Harness 调度代码，也不需要改前端。
 */
public final class ProviderNames {

    private ProviderNames() {
    }

    /** 本地模拟实现，不需要任何密钥，课设默认走这个 */
    public static final String MOCK = "mock";

    /** Stable Diffusion 系（自建或云端 SD WebUI / ComfyUI） */
    public static final String STABLE_DIFFUSION = "stable-diffusion";

    /** OpenAI DALL·E / Sora */
    public static final String OPENAI = "openai";

    /** 火山引擎即梦（国内可直连，视频能力强） */
    public static final String VOLCENGINE = "volcengine";

    /** 阿里云通义万相 */
    public static final String ALIYUN = "aliyun";
}
