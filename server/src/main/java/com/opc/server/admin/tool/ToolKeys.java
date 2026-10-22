package com.opc.server.admin.tool;

/**
 * 内置工具标识常量。
 *
 * <p>与 {@code docs/admin-freeze.md} 冻结项 ② 的 ToolKind 一一对应；
 * BUILTIN 工具的 {@code toolRefId} 为 null，靠这里的 toolKey 定位。
 */
public final class ToolKeys {

    public static final String MODEL_CALL = "MODEL_CALL";
    public static final String WEB_SEARCH = "WEB_SEARCH";
    public static final String KB_RETRIEVE = "KB_RETRIEVE";
    public static final String CODE_RUN = "CODE_RUN";
    public static final String IMAGE_PROCESS = "IMAGE_PROCESS";
    public static final String DB_QUERY = "DB_QUERY";
    public static final String HTTP_REQUEST = "HTTP_REQUEST";
    public static final String HUMAN_REVIEW = "HUMAN_REVIEW";

    private ToolKeys() {
    }
}
