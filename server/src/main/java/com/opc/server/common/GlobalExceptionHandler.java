package com.opc.server.common;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.servlet.NoHandlerFoundException;

import java.util.stream.Collectors;

/**
 * 全局异常捕获。
 *
 * <p>目标是让 Controller / Service 里**一行 try-catch 都不用写**：
 * 业务失败抛 {@link BizException}，参数校验失败交给 Bean Validation，
 * 其余未预料的异常走兜底分支，全部由这里统一翻译成前端认识的响应体。
 *
 * <p>关键设计：HTTP 状态码默认一律返回 200（业务成败看 body 里的 code），
 * <b>唯独 401 必须真的返回 HTTP 401</b> —— 前端 AuthInterceptor 靠它
 * 触发「登录失效 → 踢回登录页」。
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /** 业务异常：预期内的失败，用 warn 级别，不打印堆栈，避免日志被刷爆。 */
    @ExceptionHandler(BizException.class)
    public ResponseEntity<Result<Void>> handleBizException(
            BizException e, HttpServletRequest request) {

        log.warn("业务异常 [{} {}] code={} message={}",
                request.getMethod(), request.getRequestURI(),
                e.getErrorCode().getCode(), e.getMessage());

        HttpStatus status = e.getHttpStatus() == null ? HttpStatus.OK : e.getHttpStatus();
        return ResponseEntity.status(status)
                .body(Result.error(e.getErrorCode().getCode(), e.getMessage()));
    }

    /**
     * 参数校验失败（@Valid 触发）。
     *
     * <p>把「字段名: 提示」拼成一句话返回，前端可以直接上屏，
     * 不用再去解析嵌套的校验结构。
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Result<Void>> handleValidationException(
            MethodArgumentNotValidException e) {

        String message = e.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .filter(m -> m != null && !m.isBlank())
                .collect(Collectors.joining("；"));

        if (message.isBlank()) {
            message = ErrorCode.BAD_REQUEST.getMessage();
        }

        log.warn("参数校验失败: {}", message);
        return ResponseEntity.ok(Result.error(ErrorCode.BAD_REQUEST.getCode(), message));
    }

    /** 缺少必填的请求参数。 */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Result<Void>> handleMissingParam(
            MissingServletRequestParameterException e) {

        String message = "缺少必填参数：" + e.getParameterName();
        return ResponseEntity.ok(Result.error(ErrorCode.BAD_REQUEST.getCode(), message));
    }

    /** 上传文件超过配置上限。 */
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<Result<Void>> handleMaxUploadSize(MaxUploadSizeExceededException e) {
        log.warn("上传文件超限: {}", e.getMessage());
        return ResponseEntity.ok(Result.error(ErrorCode.FILE_TOO_LARGE));
    }

    /** 路径不存在。 */
    @ExceptionHandler(NoHandlerFoundException.class)
    public ResponseEntity<Result<Void>> handleNoHandler(NoHandlerFoundException e) {
        return ResponseEntity.ok(
                Result.error(ErrorCode.NOT_FOUND.getCode(), "接口不存在：" + e.getRequestURL()));
    }

    /**
     * 兜底：所有没预料到的异常。
     *
     * <p>这里必须打完整堆栈 —— 走到这一层说明是代码 bug，不是用户操作问题，
     * 堆栈是唯一的排查线索。同时对外只返回笼统提示，不泄露内部细节。
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Result<Void>> handleUnexpected(
            Exception e, HttpServletRequest request) {

        log.error("未预期的异常 [{} {}]", request.getMethod(), request.getRequestURI(), e);
        return ResponseEntity.ok(Result.error(ErrorCode.INTERNAL_ERROR));
    }
}
