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
 * 素材，对应 {@code t_material}。
 *
 * <p>用户上传的参考素材（垫图、首帧图）。本轮后端先建好表与实体，
 * 上传接口等「素材库」页面开发时再接。
 */
@Entity
@Table(name = "t_material")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Material extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "url", nullable = false, length = 255)
    private String url;

    @Column(name = "thumb_url", length = 255)
    private String thumbUrl;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "width")
    private Integer width;

    @Column(name = "height")
    private Integer height;

    @Column(name = "mime_type", length = 50)
    private String mimeType;

    /** 来源：UPLOAD / CAMERA / GENERATED */
    @Column(name = "source", nullable = false, length = 20)
    @Builder.Default
    private String source = "UPLOAD";

    @Column(name = "group_name", length = 50)
    private String groupName;

    /** 标签，逗号分隔 */
    @Column(name = "tags", length = 255)
    private String tags;

    /** 逻辑删除（DB 列是 TINYINT，Java 侧用布尔语义以支持 DeletedFalse 派生查询） */
    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
