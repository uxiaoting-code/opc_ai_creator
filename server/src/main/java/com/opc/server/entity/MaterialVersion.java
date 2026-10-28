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
 * 素材版本快照。标签 ID 以 JSON 数组保存，避免版本记录随标签改名而漂移。
 */
@Entity
@Table(name = "t_material_version")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaterialVersion extends BaseEntity {

    @Column(name = "material_id", nullable = false)
    private Long materialId;

    @Column(name = "version_no", nullable = false)
    private Integer versionNo;

    @Column(name = "title", nullable = false, length = 100)
    private String title;

    @Column(name = "category_id")
    private Long categoryId;

    @Column(name = "tag_ids_json", length = 2000)
    private String tagIdsJson;

    @Column(name = "file_url", nullable = false, length = 255)
    private String fileUrl;

    @Column(name = "thumb_url", length = 255)
    private String thumbUrl;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "mime_type", length = 50)
    private String mimeType;

    @Column(name = "width")
    private Integer width;

    @Column(name = "height")
    private Integer height;

    @Column(name = "change_note", length = 500)
    private String changeNote;

    @Column(name = "created_by")
    private Long createdBy;
}
