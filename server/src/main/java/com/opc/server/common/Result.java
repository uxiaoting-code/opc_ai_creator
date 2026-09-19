package com.opc.server.common;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * 统一响应体。
 *
 * <p>与前端 {@code lib/core/network/api_response.dart} 里的 {@code ApiResponse<T>}
 * 严格一一对应，字段名不能改：
 * <pre>
 * { "code": 200, "message": "success", "data": {...}, "timestamp": 1737000000000 }
 * </pre>
 *
 * <p>约定：{@code code == 200} 表示业务成功，其余都是失败，
 * 前端 {@code ApiClient} 会据此抛 {@code ApiException}。
 *
 * @param <T> 业务数据类型
 */
@JsonInclude(JsonInclude.Include.ALWAYS)
public record Result<T>(
        int code,
        String message,
        T data,
        long timestamp
) {

    /** 成功码。前端 {@code ApiResponse.isSuccess} 判断的就是它。 */
    public static final int CODE_SUCCESS = 200;

    public static <T> Result<T> success(T data) {
        return new Result<>(CODE_SUCCESS, "success", data, System.currentTimeMillis());
    }

    public static Result<Void> success() {
        return success(null);
    }

    public static <T> Result<T> success(T data, String message) {
        return new Result<>(CODE_SUCCESS, message, data, System.currentTimeMillis());
    }

    public static <T> Result<T> error(int code, String message) {
        return new Result<>(code, message, null, System.currentTimeMillis());
    }

    public static <T> Result<T> error(ErrorCode errorCode) {
        return error(errorCode.getCode(), errorCode.getMessage());
    }

    public static <T> Result<T> error(ErrorCode errorCode, String message) {
        return error(errorCode.getCode(), message);
    }
}
