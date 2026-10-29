package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** 知识库文档，对应 {@code t_kb_document}。 */
@Entity
@Table(name = "t_kb_document")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KbDocument extends BaseEntity {

    @Column(name = "kb_id", nullable = false)
    private Long kbId;

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    /** TEXT / FILE / URL / API_SYNC */
    @Column(name = "source_type", nullable = false, length = 20)
    private String sourceType;

    @Column(name = "source_url", length = 500)
    private String sourceUrl;

    @Column(name = "content", columnDefinition = "TEXT")
    private String content;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "chunk_count", nullable = false)
    @Builder.Default
    private Integer chunkCount = 0;

    /** READY / FAILED */
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "READY";

    @Column(name = "error_msg", length = 1000)
    private String errorMsg;

    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
