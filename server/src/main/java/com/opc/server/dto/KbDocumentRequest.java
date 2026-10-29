package com.opc.server.dto;

/**
 * 录入文档（TEXT / URL / API_SYNC）。
 * 文件上传走 multipart 接口。
 */
public record KbDocumentRequest(
        String name,
        String type,
        String content,
        String url,
        String apiHeadersJson
) {
}
