package com.opc.server.entity.enums;

/**
 * AI 任务类型，对应 {@code t_ai_task.type}。
 *
 * <p>取值必须与前端 SkillType / 创作接口保持一致。
 */
public enum TaskType {

    /** 文生图 */
    TEXT_TO_IMAGE("文生图"),

    /** 图生视频 */
    IMAGE_TO_VIDEO("图生视频"),

    /** 文本转音频 */
    TEXT_TO_AUDIO("文本转音频");

    private final String label;

    TaskType(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    /** 图生视频必须提供首帧参考图。 */
    public boolean requiresReferenceImage() {
        return this == IMAGE_TO_VIDEO;
    }

    /** 任务类型对应的提交媒体类型。 */
    public MediaType mediaType() {
        return switch (this) {
            case TEXT_TO_IMAGE -> MediaType.IMAGE;
            case IMAGE_TO_VIDEO -> MediaType.VIDEO;
            case TEXT_TO_AUDIO -> MediaType.AUDIO;
        };
    }
}