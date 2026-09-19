package com.opc.server.dto;

import com.opc.server.entity.Skill;

import java.math.BigDecimal;

/**
 * Skill 线路响应。
 *
 * <p>字段名与前端 {@code lib/data/models/skill_model.dart} 的 {@code SkillModel}
 * <b>严格对齐</b>，前端 {@code SkillModel.fromJson} 可以直接解析。
 */
public record SkillResponse(
        Long id,
        String code,
        String name,

        /** 取值 {@code TEXT_TO_IMAGE} / {@code IMAGE_TO_VIDEO}，与前端枚举的 value 一致 */
        String type,
        String typeLabel,

        String coverUrl,
        String description,
        String scene,

        String provider,
        String modelName,
        String sampler,
        Integer steps,
        BigDecimal cfgScale,
        Integer width,
        Integer height,

        String promptPrefix,
        String promptSuffix,
        String negativePrompt,

        Integer usageCount,
        Integer favoriteCount,
        Integer status
) {

    public static SkillResponse from(Skill skill) {
        if (skill == null) {
            return null;
        }
        return new SkillResponse(
                skill.getId(),
                skill.getCode(),
                skill.getName(),
                // 用枚举的 value 而不是 name()：保证与前端约定的字符串完全一致，
                // 将来枚举名重构也不会悄悄改掉接口契约
                skill.getType() == null ? null : skill.getType().getValue(),
                skill.getType() == null ? null : skill.getType().getLabel(),
                skill.getCoverUrl(),
                skill.getDescription(),
                skill.getScene(),
                skill.getProvider(),
                skill.getModelName(),
                skill.getSampler(),
                skill.getSteps(),
                skill.getCfgScale(),
                skill.getWidth(),
                skill.getHeight(),
                skill.getPromptPrefix(),
                skill.getPromptSuffix(),
                skill.getNegativePrompt(),
                skill.getUsageCount(),
                skill.getFavoriteCount(),
                skill.getStatus()
        );
    }
}
