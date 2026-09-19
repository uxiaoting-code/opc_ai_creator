package com.opc.server.entity.enums;

/**
 * 作品类型，对应 {@code t_work.type}。
 *
 * <p>与前端 {@code lib/data/models/work_model.dart} 的 {@code WorkType} 对齐。
 */
public enum WorkType {

    IMAGE("IMAGE", "图片"),
    VIDEO("VIDEO", "视频");

    private final String value;
    private final String label;

    WorkType(String value, String label) {
        this.value = value;
        this.label = label;
    }

    public String getValue() {
        return value;
    }

    public String getLabel() {
        return label;
    }

    /**
     * 由任务类型推导作品类型：
     * 文生图产出图片，图生视频产出视频。
     */
    public static WorkType fromTaskType(TaskType taskType) {
        return taskType == TaskType.IMAGE_TO_VIDEO ? VIDEO : IMAGE;
    }
}
