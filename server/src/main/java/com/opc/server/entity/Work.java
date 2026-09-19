package com.opc.server.entity;

import com.opc.server.entity.enums.WorkType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 作品，对应 {@code t_work}。
 *
 * <p>与 {@link AiTask} 的区别：任务记录**执行过程**（排队/生成中/失败重试），
 * 作品记录**用户可见的成果**。任务可以删、可以过期清理，作品要长期留在画廊。
 *
 * <p>任务成功时由 Harness 自动落一条作品记录。
 */
@Entity
@Table(name = "t_work")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Work extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** 来源任务 ID */
    @Column(name = "task_id")
    private Long taskId;

    @Column(name = "title", length = 100)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private WorkType type;

    /** 封面（视频取首帧） */
    @Column(name = "cover_url", length = 255)
    private String coverUrl;

    /** 作品资源地址（图片 URL 或视频 URL） */
    @Column(name = "resource_url", nullable = false, length = 255)
    private String resourceUrl;

    @Column(name = "prompt", length = 2000)
    private String prompt;

    @Column(name = "negative_prompt", length = 1000)
    private String negativePrompt;

    @Column(name = "skill_id")
    private Long skillId;

    @Column(name = "params_json", length = 4000)
    private String paramsJson;

    @Column(name = "width")
    private Integer width;

    @Column(name = "height")
    private Integer height;

    /** 视频时长（秒） */
    @Column(name = "duration")
    private Integer duration;

    /** 1 发布到公开画廊 / 0 仅自己可见 */
    @Column(name = "is_public", nullable = false)
    @Builder.Default
    private Boolean isPublic = false;

    @Column(name = "like_count", nullable = false)
    @Builder.Default
    private Integer likeCount = 0;

    @Column(name = "view_count", nullable = false)
    @Builder.Default
    private Integer viewCount = 0;

    /** 逻辑删除（DB 列是 TINYINT，Java 侧用布尔语义以支持 DeletedFalse 派生查询） */
    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;

    /** 线路名称，联表带出，列表展示用 */
    @Transient
    private String skillName;

    /** 从任务生成作品记录。 */
    public static Work fromTask(AiTask task, String skillName, String coverUrl) {
        return Work.builder()
                .userId(task.getUserId())
                .taskId(task.getId())
                .title(buildTitle(task))
                .type(WorkType.fromTaskType(task.getType()))
                .coverUrl(coverUrl)
                .resourceUrl(task.getResultUrl())
                .prompt(task.getPrompt())
                .negativePrompt(task.getNegativePrompt())
                .skillId(task.getSkillId())
                .paramsJson(task.getParamsJson())
                .isPublic(false)
                .likeCount(0)
                .viewCount(0)
                .deleted(false)
                .build();
    }

    /** 用提示词前 20 个字当标题，用户没填标题时列表也有东西可显示。 */
    private static String buildTitle(AiTask task) {
        String prompt = task.getPrompt();
        if (prompt == null || prompt.isBlank()) {
            return "未命名作品";
        }
        String trimmed = prompt.trim();
        return trimmed.length() > 20 ? trimmed.substring(0, 20) : trimmed;
    }
}
