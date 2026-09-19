package com.opc.server.common;

/**
 * 业务错误码。
 *
 * <p>与 HTTP 状态码解耦：HTTP 层一律返回 200，业务成败看响应体里的 {@code code}。
 * 但 401 是个例外 —— 前端 {@code AuthInterceptor} 专门靠 HTTP 401 来触发
 * 「登录失效 → 踢回登录页」，所以鉴权失败时必须同时把 HTTP 状态码也置为 401。
 */
public enum ErrorCode {

    // --- 通用 ---
    BAD_REQUEST(400, "请求参数有误"),
    UNAUTHORIZED(401, "登录已过期，请重新登录"),
    FORBIDDEN(403, "没有权限执行该操作"),
    NOT_FOUND(404, "请求的资源不存在"),
    INTERNAL_ERROR(500, "服务器开小差了，请稍后重试"),

    // --- 用户 / 鉴权 ---
    USERNAME_EXISTS(1001, "该账号已被注册"),
    USER_NOT_FOUND(1002, "用户不存在"),
    PASSWORD_ERROR(1003, "账号或密码错误"),
    ACCOUNT_DISABLED(1004, "账号已被禁用"),

    // --- Skill 线路 ---
    SKILL_NOT_FOUND(2001, "创作线路不存在"),
    SKILL_OFFLINE(2002, "该创作线路已下线"),

    // --- Harness 任务 ---
    TASK_NOT_FOUND(3001, "任务不存在"),
    TASK_STATUS_ILLEGAL(3002, "当前任务状态下不允许该操作"),
    TASK_RETRY_EXHAUSTED(3003, "重试次数已用尽"),
    NO_PROVIDER_AVAILABLE(3004, "没有可用的 AI 服务商"),

    // --- 文件 ---
    FILE_EMPTY(4001, "上传文件为空"),
    FILE_TYPE_NOT_ALLOWED(4002, "不支持的文件类型"),
    FILE_TOO_LARGE(4003, "文件体积超出限制"),
    FILE_SAVE_FAILED(4004, "文件保存失败"),

    // --- 作品 ---
    WORK_NOT_FOUND(5001, "作品不存在");

    private final int code;
    private final String message;

    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }

    public int getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }
}
