package com.opc.server.dto;

import com.opc.server.entity.Work;

import java.time.LocalDateTime;

/**
 * 作品响应。
 *
 * <p>字段名与前端 {@code lib/data/models/work_model.dart} 的 {@code WorkModel}
 * 严格对齐。
 *
 * <p>注意 {@code isPublic} 的序列化：实体里刻意用包装类型 {@code Boolean}
 * 而不是基本类型 {@code boolean}。基本类型时 Lombok 生成的 getter 是
 * {@code isPublic()}，Jackson 会把属性名推断成 {@code public}，
 * 前端就拿不到 {@code isPublic} 了。包装类型生成 {@code getIsPublic()}，
 * 属性名才是正确的 {@code isPublic}。
 */
public record WorkResponse(
        Long id,
        Long userId,
        Long taskId,
        String title,
        String type,
        String coverUrl,
        String resourceUrl,
        String prompt,
        String negativePrompt,
        Long skillId,
        String skillName,
        Integer width,
        Integer height,
        Integer duration,
        Boolean isPublic,
        Integer likeCount,
        Integer viewCount,
        LocalDateTime createdAt
) {

    public static WorkResponse from(Work work) {
        if (work == null) {
            return null;
        }
        return new WorkResponse(
                work.getId(),
                work.getUserId(),
                work.getTaskId(),
                work.getTitle(),
                work.getType() == null ? null : work.getType().getValue(),
                work.getCoverUrl(),
                work.getResourceUrl(),
                work.getPrompt(),
                work.getNegativePrompt(),
                work.getSkillId(),
                work.getSkillName(),
                work.getWidth(),
                work.getHeight(),
                work.getDuration(),
                work.getIsPublic(),
                work.getLikeCount(),
                work.getViewCount(),
                work.getCreatedAt()
        );
    }
}
