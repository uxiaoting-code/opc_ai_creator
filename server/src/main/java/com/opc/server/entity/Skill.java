package com.opc.server.entity;

import com.opc.server.entity.enums.SkillType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/**
 * Skill 创作线路，对应 {@code t_skill}。
 *
 * <p>一条 Skill = 一整套生成参数模板（模型、采样器、步数、提示词前后缀…）。
 * <b>它是「多线路」需求的载体</b>：新增一条线路只需往表里插一行，
 * 前后端都不用改代码、不用重新打包。
 *
 * <p>其中 {@code provider} 字段是 MCP 思想的关键 —— 它决定这个线路
 * 由哪个 {@code AiProvider} 实现类执行，见 {@code AiProviderRouter}。
 */
@Entity
@Table(name = "t_skill")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Skill extends BaseEntity {

    /** 线路编码，如 {@code anime_v1}，全局唯一 */
    @Column(name = "code", nullable = false, length = 50, unique = true)
    private String code;

    /** 线路名称，如「二次元插画」 */
    @Column(name = "name", nullable = false, length = 50)
    private String name;

    /** 适用类型：文生图 / 图生视频 */
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private SkillType type;

    @Column(name = "cover_url", length = 255)
    private String coverUrl;

    @Column(name = "description", length = 500)
    private String description;

    /** 适用场景，如「头像 / 立绘」 */
    @Column(name = "scene", length = 100)
    private String scene;

    // -----------------------------------------------------------------------
    // 以下为 MCP 思想的「能力描述」部分：服务商 + 模型 + 推理参数
    // -----------------------------------------------------------------------

    /** AI 服务商标识，对应 AiProvider 实现类的 name，如 {@code mock} */
    @Column(name = "provider", nullable = false, length = 50)
    @Builder.Default
    private String provider = "mock";

    /** 模型名，如 {@code sd-xl-anime} */
    @Column(name = "model_name", length = 100)
    private String modelName;

    @Column(name = "sampler", length = 50)
    private String sampler;

    @Column(name = "steps", nullable = false)
    @Builder.Default
    private Integer steps = 25;

    @Column(name = "cfg_scale", nullable = false, precision = 4, scale = 1)
    @Builder.Default
    private BigDecimal cfgScale = new BigDecimal("7.0");

    @Column(name = "width", nullable = false)
    @Builder.Default
    private Integer width = 1024;

    @Column(name = "height", nullable = false)
    @Builder.Default
    private Integer height = 1024;

    // -----------------------------------------------------------------------
    // 提示词模板：拼接在用户输入前后，保证风格稳定
    // -----------------------------------------------------------------------

    @Column(name = "prompt_prefix", length = 500)
    private String promptPrefix;

    @Column(name = "prompt_suffix", length = 500)
    private String promptSuffix;

    @Column(name = "negative_prompt", length = 500)
    private String negativePrompt;

    /** 扩展参数（JSON 字符串），新增参数无需改表结构 */
    @Column(name = "params_json", length = 4000)
    private String paramsJson;

    @Column(name = "usage_count", nullable = false)
    @Builder.Default
    private Integer usageCount = 0;

    @Column(name = "favorite_count", nullable = false)
    @Builder.Default
    private Integer favoriteCount = 0;

    @Column(name = "sort_order", nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;

    /** 1 启用 / 0 下线 */
    @Column(name = "status", nullable = false)
    @Builder.Default
    private Integer status = 1;

    public boolean isOnline() {
        return status != null && status == 1;
    }

    /**
     * 把用户输入的提示词套进线路模板。
     *
     * <p>这是「线路」真正起作用的地方：同一条提示词走不同线路，
     * 前面被拼上不同的风格前缀，出图风格就完全不同。
     */
    public String buildFinalPrompt(String userPrompt) {
        StringBuilder sb = new StringBuilder();
        if (promptPrefix != null && !promptPrefix.isBlank()) {
            sb.append(promptPrefix.trim()).append(", ");
        }
        if (userPrompt != null && !userPrompt.isBlank()) {
            sb.append(userPrompt.trim());
        }
        if (promptSuffix != null && !promptSuffix.isBlank()) {
            if (!sb.isEmpty()) {
                sb.append(", ");
            }
            sb.append(promptSuffix.trim());
        }
        return sb.toString();
    }

    /** 用户没填负面提示词时，用线路自带的兜底。 */
    public String resolveNegativePrompt(String userNegativePrompt) {
        if (userNegativePrompt != null && !userNegativePrompt.isBlank()) {
            return userNegativePrompt.trim();
        }
        return negativePrompt;
    }

    /** 使用次数 +1（线路创建任务时调用）。 */
    public void increaseUsage() {
        usageCount = (usageCount == null ? 0 : usageCount) + 1;
    }
}
