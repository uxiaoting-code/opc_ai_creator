package com.opc.server.entity.enums;

/**
 * AI 任务类型，对应 {@code t_ai_task.type}。
 *
 * <p>取值必须与前端 {@code lib/data/models/skill_model.dart} 里
 * {@code SkillType} 的字符串完全一致，否则线路和任务对不上。
 */
public enum TaskType {

    /** 文生图 */
    TEXT_TO_IMAGE("文生图"),

    /** 图生视频 */
    IMAGE_TO_VIDEO("图生视频");

    private final String label;

    TaskType(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    /** 图生视频必须提供首帧参考图，文生图不需要。 */
    public boolean requiresReferenceImage() {
        return this == IMAGE_TO_VIDEO;
    }
}
