package com.opc.server.ai;

import com.opc.server.entity.enums.TaskType;

import java.util.Map;

/**
 * 调用 AI 服务商的统一请求载体。
 *
 * <p><b>这是 MCP 思想里「参数解耦」的落点。</b>
 * 不同服务商的参数差异很大（Stable Diffusion 要 steps/cfgScale，
 * DALL·E 只认 size，视频模型要 duration/fps），
 * 但调用方只构造这一个对象，各 Provider 实现类在内部自己做参数翻译。
 *
 * <p>刻意不让本类引用 {@code AiTask} / {@code Skill} 实体 ——
 * AI 层不认识持久化模型，实体到本对象的转换由 Service 层完成。
 * 这样新增一个服务商实现，不需要碰任何数据库代码。
 *
 * @param taskNo            任务编号，作为幂等键传给服务商
 * @param taskType          文生图 / 图生视频
 * @param prompt            最终提示词（已拼接线路的风格前缀后缀）
 * @param negativePrompt    负面提示词，可为 null
 * @param referenceImageUrl 参考图 / 首帧图地址，图生视频必填
 * @param skillCode         线路编码，便于服务商侧做统计
 * @param modelName         模型名，如 sd-xl-anime
 * @param steps             采样步数
 * @param cfgScale          提示词引导强度
 * @param width             输出宽
 * @param height            输出高
 * @param seed              随机种子，null 表示随机
 * @param retryCount        当前是第几次尝试（从 0 开始），供 Provider 做差异化行为
 * @param extraParams       线路 paramsJson 解析出的扩展参数，新增参数不用改接口
 */
public record AiTaskRequest(
        String taskNo,
        TaskType taskType,
        String prompt,
        String negativePrompt,
        String referenceImageUrl,
        String skillCode,
        String modelName,
        Integer steps,
        Double cfgScale,
        Integer width,
        Integer height,
        Long seed,
        Integer retryCount,
        Map<String, Object> extraParams
) {

    /** 输出尺寸兜底：服务商没给就按 1024×1024。 */
    public int safeWidth() {
        return (width == null || width <= 0) ? 1024 : Math.min(width, 2048);
    }

    public int safeHeight() {
        return (height == null || height <= 0) ? 1024 : Math.min(height, 2048);
    }

    /** 展平成一个 map，方便直接塞进服务商的 JSON body。 */
    public Map<String, Object> toFlatMap() {
        return Map.of(
                "taskNo", String.valueOf(taskNo),
                "prompt", String.valueOf(prompt),
                "negativePrompt", String.valueOf(negativePrompt),
                "width", safeWidth(),
                "height", safeHeight(),
                "model", String.valueOf(modelName)
        );
    }
}
