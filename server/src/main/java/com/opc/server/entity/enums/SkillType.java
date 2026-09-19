package com.opc.server.entity.enums;

/**
 * Skill 线路适用类型，对应 {@code t_skill.type}。
 *
 * <p>取值必须与前端 {@code SkillType} 的字符串一致。
 */
public enum SkillType {

    TEXT_TO_IMAGE("TEXT_TO_IMAGE", "文生图"),
    IMAGE_TO_VIDEO("IMAGE_TO_VIDEO", "图生视频");

    private final String value;
    private final String label;

    SkillType(String value, String label) {
        this.value = value;
        this.label = label;
    }

    public String getValue() {
        return value;
    }

    public String getLabel() {
        return label;
    }

    /** 线路类型 → 任务类型。 */
    public TaskType toTaskType() {
        return this == IMAGE_TO_VIDEO ? TaskType.IMAGE_TO_VIDEO : TaskType.TEXT_TO_IMAGE;
    }

    /** 任务类型 → 线路类型（查线路时用）。 */
    public static SkillType fromTaskType(TaskType taskType) {
        return taskType == TaskType.IMAGE_TO_VIDEO ? IMAGE_TO_VIDEO : TEXT_TO_IMAGE;
    }
}
