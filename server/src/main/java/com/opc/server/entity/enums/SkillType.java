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

    /**
     * 宽容解析：把数据库里的字符串转成枚举。
     *
     * <p><b>认不出来就返回 null，绝不抛异常。</b>
     *
     * <p>为什么必须这么设计：{@code @Enumerated(EnumType.STRING)} 的默认行为是
     * 遇到不认识的值直接抛 {@code IllegalArgumentException} —— 这意味着
     * <b>表里只要有一行脏数据，整个列表接口就 500</b>。
     * 实际就踩到了：某行 {@code type} 写成了 {@code text2img}，
     * 于是首页「创作线路」整块显示"服务器开小差了"，
     * 而传 {@code ?type=TEXT_TO_IMAGE} 时又完全正常（SQL 把脏行过滤掉了）——
     * 这种"时好时坏"最难查。
     *
     * <p>一行运营配置写错不该有这种破坏力。降级成 null，
     * 由调用方决定怎么处理（{@link SkillService} 会把这类行直接跳过）。
     *
     * <p>大小写不敏感，顺便容忍 {@code text_to_image} 这种写法。
     */
    public static SkillType fromValue(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        for (SkillType type : values()) {
            if (type.value.equalsIgnoreCase(value) || type.name().equalsIgnoreCase(value)) {
                return type;
            }
        }
        return null;
    }
}
