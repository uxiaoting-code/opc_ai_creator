package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Prompt 知识库条目，对应 {@code t_prompt}。
 *
 * <p>本轮后端先建好表与实体；检索、收藏接口等「Prompt 知识库」页面
 * 开发时再接。表上已有 ngram 全文索引，届时直接写查询即可。
 */
@Entity
@Table(name = "t_prompt")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Prompt extends BaseEntity {

    /** 投稿者；null 表示官方内置 */
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "title", nullable = false, length = 100)
    private String title;

    @Column(name = "content", nullable = false, length = 4000)
    private String content;

    @Column(name = "negative_content", length = 2000)
    private String negativeContent;

    /** 分类：人物 / 风景 / 电商 / 二次元 / 建筑 */
    @Column(name = "category", length = 50)
    private String category;

    /** 标签，逗号分隔，检索用 */
    @Column(name = "tags", length = 255)
    private String tags;

    @Column(name = "cover_url", length = 255)
    private String coverUrl;

    @Column(name = "favorite_count", nullable = false)
    @Builder.Default
    private Integer favoriteCount = 0;

    @Column(name = "use_count", nullable = false)
    @Builder.Default
    private Integer useCount = 0;

    @Column(name = "is_public", nullable = false)
    @Builder.Default
    private Integer isPublic = 1;

    @Column(name = "status", nullable = false)
    @Builder.Default
    private Integer status = 1;

    /** 逻辑删除（DB 列是 TINYINT，Java 侧用布尔语义以支持 DeletedFalse 派生查询） */
    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
