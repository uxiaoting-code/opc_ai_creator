package com.opc.server.security;

/**
 * 当前请求的登录用户。
 *
 * <p>用 {@link ThreadLocal} 保存，由 {@link AuthInterceptor} 在请求进入时写入、
 * 请求结束时清理。这样 Service 层不用在每个方法签名上都挂一个 {@code userId} 参数。
 *
 * <p><b>清理是必须的</b>：Tomcat 用线程池处理请求，线程会被复用。
 * 如果不清理，下一个请求可能读到上一个用户残留的 ID —— 这是很严重的越权漏洞。
 */
public final class UserContext {

    private static final ThreadLocal<Long> CURRENT_USER_ID = new ThreadLocal<>();

    private UserContext() {
    }

    public static void set(Long userId) {
        CURRENT_USER_ID.set(userId);
    }

    /**
     * 取当前用户 ID。
     *
     * <p>拿不到说明拦截器没放行就进了业务代码，属于编码错误，
     * 直接抛异常比返回 null 更安全（返回 null 会导致后续查询变成「查所有人」）。
     */
    public static Long require() {
        Long userId = CURRENT_USER_ID.get();
        if (userId == null) {
            throw new IllegalStateException(
                    "当前请求没有登录用户，请确认该接口已纳入 AuthInterceptor 的拦截范围");
        }
        return userId;
    }

    /** 可以为空的版本，用于日志等非关键路径。 */
    public static Long get() {
        return CURRENT_USER_ID.get();
    }

    public static void clear() {
        CURRENT_USER_ID.remove();
    }
}
