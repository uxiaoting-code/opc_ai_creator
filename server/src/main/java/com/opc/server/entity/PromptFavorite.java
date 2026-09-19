package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 提示词收藏关联，对应 {@code t_prompt_favorite}。
 *
 * <p>用户与提示词是多对多，必须有这张中间表。
 * {@code (user_id, prompt_id)} 上的唯一约束既防重复收藏，
 * 又天然支持「我是否已收藏」的快速判定。
 */
@Entity
@Table(
        name = "t_prompt_favorite",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_user_prompt",
                columnNames = {"user_id", "prompt_id"}
        )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PromptFavorite extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "prompt_id", nullable = false)
    private Long promptId;
}
