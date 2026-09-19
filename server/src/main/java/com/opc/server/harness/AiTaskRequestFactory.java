package com.opc.server.harness;

// Jackson 3：databind/core 的包名是 tools.jackson.*，注解仍是 com.fasterxml.jackson.annotation.*
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;
import com.opc.server.ai.AiTaskRequest;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.Skill;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.Map;

/**
 * 把持久化实体翻译成 AI 层认识的 {@link AiTaskRequest}。
 *
 * <p>这个类存在的意义是<b>保持依赖方向单向</b>：
 * {@code harness → ai}、{@code harness → entity}，
 * 而 {@code ai} 包不认识任何实体。
 *
 * <p>好处是接新服务商时，那个实现类只需要处理纯数据对象，
 * 不会因为实体字段调整而被牵连；也让 AI 层可以脱离数据库单独测试。
 */
@Component
public class AiTaskRequestFactory {

    private static final Logger log = LoggerFactory.getLogger(AiTaskRequestFactory.class);

    private final ObjectMapper objectMapper;

    public AiTaskRequestFactory(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    /**
     * 组装请求。
     *
     * @param task  任务实体，提供提示词与类型
     * @param skill 线路配置，提供模型与推理参数；可为 null（线路被删的情况）
     */
    public AiTaskRequest build(AiTask task, Skill skill) {
        return new AiTaskRequest(
                task.getTaskNo(),
                task.getType(),
                task.getPrompt(),
                task.getNegativePrompt(),
                task.getRefImageUrl(),
                skill == null ? null : skill.getCode(),
                skill == null ? null : skill.getModelName(),
                skill == null ? null : skill.getSteps(),
                skill == null || skill.getCfgScale() == null
                        ? null : skill.getCfgScale().doubleValue(),
                skill == null ? null : skill.getWidth(),
                skill == null ? null : skill.getHeight(),
                null,                       // seed：本轮不开放用户指定，服务商侧随机
                task.getRetryCount(),
                parseExtraParams(skill)
        );
    }

    /**
     * 解析线路的扩展参数。
     *
     * <p>解析失败不能让任务挂掉 —— 扩展参数是可选的锦上添花，
     * 坏了就当作没有，任务照常跑。
     */
    private Map<String, Object> parseExtraParams(Skill skill) {
        if (skill == null || skill.getParamsJson() == null || skill.getParamsJson().isBlank()) {
            return Collections.emptyMap();
        }
        try {
            return objectMapper.readValue(
                    skill.getParamsJson(), new TypeReference<Map<String, Object>>() {
                    });
        } catch (Exception e) {
            log.warn("线路 {} 的 paramsJson 解析失败，已忽略: {}",
                    skill.getCode(), e.getMessage());
            return Collections.emptyMap();
        }
    }
}
