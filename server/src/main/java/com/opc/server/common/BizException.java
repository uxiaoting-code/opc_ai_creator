package com.opc.server.common;

import org.springframework.http.HttpStatus;

/**
 * 业务异常。
 *
 * <p>Service 层抛这个异常，由 {@link GlobalExceptionHandler} 统一翻译成响应体，
 * 业务代码里不需要写 try-catch 拼错误响应。
 */
public class BizException extends RuntimeException {

    private final ErrorCode errorCode;

    /** 需要额外覆盖 HTTP 状态码时使用（目前只有 401 会用到）。 */
    private final HttpStatus httpStatus;

    public BizException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
        this.httpStatus = null;
    }

    public BizException(ErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = null;
    }

    public BizException(ErrorCode errorCode, String message, HttpStatus httpStatus) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }

    /**
     * 鉴权失败。
     *
     * <p>必须同时把 HTTP 状态码置为 401：前端的 AuthInterceptor 是靠
     * HTTP 401 来触发「登录失效 → 踢回登录页」的，只改业务码前端收不到。
     */
    public static BizException unauthorized(String message) {
        return new BizException(ErrorCode.UNAUTHORIZED, message, HttpStatus.UNAUTHORIZED);
    }

    public static BizException notFound(ErrorCode errorCode) {
        return new BizException(errorCode);
    }

    public ErrorCode getErrorCode() {
        return errorCode;
    }

    public HttpStatus getHttpStatus() {
        return httpStatus;
    }
}
