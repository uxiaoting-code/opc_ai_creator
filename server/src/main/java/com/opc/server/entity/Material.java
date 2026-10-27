package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.LinkedHashSet;
import java.util.Set;

/**
 * 素材，对应 {@code t_material}。
 *
 * <p>C 端上传接口继续使用 {@code name/url}；管理端在此基础上补充标题、
 * 分类、标签关联和版本号。字段只增不改，避免破坏 App 现有接口。
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

    /** 管理端展示名称；旧数据为空时回退到 name。 */
    @Column(name = "title", length = 100)
    private String title;

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

    /** 分类树节点 ID。 */
    @Column(name = "category_id")
    private Long categoryId;

    /** 旧版逗号分隔标签，保留用于兼容历史数据和关键词检索。 */
    @Column(name = "tags", length = 255)
    private String legacyTags;

    /** 管理端多级标签关联。 */
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "t_material_tag_rel",
            joinColumns = @JoinColumn(name = "material_id"),
            inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    @Builder.Default
    private Set<MaterialTag> tags = new LinkedHashSet<>();

    @Column(name = "version")
    @Builder.Default
    private Integer version = 1;

    /** 逻辑删除（DB 列是 TINYINT，Java 侧用布尔语义以支持 DeletedFalse 派生查询） */
    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
