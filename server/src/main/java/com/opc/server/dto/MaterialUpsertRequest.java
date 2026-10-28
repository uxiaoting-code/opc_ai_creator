package com.opc.server.dto;

import java.util.List;

/**
 * 管理端素材新增/更新参数。
 *
 * <p>更新接口采用部分更新：字段为 null 表示保持原值；tagIds 传空数组表示清空标签。
 */
public record MaterialUpsertRequest(
        String title,
        Long categoryId,
        List<Long> tagIds,
        String fileUrl,
        String thumbUrl,
        String mimeType,
        Long fileSize,
        Integer width,
        Integer height,
        Boolean newVersion,
        String changeNote
) {
}
