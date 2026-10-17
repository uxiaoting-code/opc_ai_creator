package com.opc.server.security;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.entity.User;
import com.opc.server.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Optional;

/**
 * 登录拦截器。
 *
 * <p>从 {@code Authorization: Bearer <token>} 解析出用户，
 * 校验通过就写进 {@link UserContext}，失败则抛 401。
 *
 * <p>不用 Spring Security 的原因：本项目只需要「有没有登录」这一件事，
 * 引入完整的 Security 会带来一整条过滤器链和默认配置的干扰
 * （比如默认开启的 CSRF、默认的表单登录页），配置成本远大于收益。
 */
@Component
public class AuthInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(AuthInterceptor.class);

    private static final String AUTH_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    /** 「最近活跃」写库节流：同一用户 5 分钟内只更新一次。 */
    private static final long LAST_ACTIVE_THROTTLE_MINUTES = 5;

    private final TokenService tokenService;
    private final UserRepository userRepository;

    /**
     * 前端脚手架模式的固定令牌，见 {@code AuthProvider._applyMockSession()}。
     *
     * <p>前端在 {@code bypassLogin = true} 时不调登录接口，直接伪造一个本地会话，
     * 携带的就是这个令牌。后端如果完全不认它，那么**后端接口一接上前端就全部 401**。
     */
    @Value("${opc.security.dev-token:mock-token-for-scaffold}")
    private String devToken;

    /**
     * 是否接受上面的开发令牌。
     *
     * <p>只应在开发阶段为 true。交付前务必改成 false ——
     * 否则任何人拿这个固定字符串就能以演示账号身份调用所有接口。
     * 启动时会打印醒目警告。
     */
    @Value("${opc.security.dev-token-enabled:true}")
    private boolean devTokenEnabled;

    /** 开发令牌对应的账号。 */
    @Value("${opc.security.dev-username:demo}")
    private String devUsername;

    public AuthInterceptor(TokenService tokenService, UserRepository userRepository) {
        this.tokenService = tokenService;
        this.userRepository = userRepository;
    }

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) {

        // 浏览器的 CORS 预检请求不带 Authorization，必须放行，
        // 否则跨域请求会在预检阶段就被 401 挡掉
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String token = extractToken(request);
        boolean adminPath = isAdminPath(request);

        // ---- 开发令牌：只允许 C 端，绝不能进管理端 ----
        // 这是交付前的关键安全点：拿固定字符串就能以 demo 身份进后台，等于后台没有鉴权。
        if (devTokenEnabled && devToken.equals(token)) {
            if (adminPath) {
                throw BizException.forbidden(
                        "管理端不允许使用开发令牌，请使用管理员账号登录");
            }
            User demoUser = userRepository.findByUsernameAndDeletedFalse(devUsername)
                    .orElseThrow(() -> BizException.unauthorized(
                            "开发令牌对应的演示账号不存在，请先执行数据初始化"));
            UserContext.set(demoUser.getId());
            touchLastActive(demoUser);
            return true;
        }

        // ---- 正常令牌 ----
        Optional<Long> userId = tokenService.resolveUserId(token);
        if (userId.isEmpty()) {
            throw BizException.unauthorized("登录已过期，请重新登录");
        }

        User user = userRepository.findByIdAndDeletedFalse(userId.get())
                .orElseThrow(() -> BizException.unauthorized("账号不存在或已被删除"));

        if (user.getStatus() == null || user.getStatus() != 1) {
            throw new BizException(ErrorCode.ACCOUNT_DISABLED);
        }

        // ---- 管理端必须是 ADMIN ----
        if (adminPath && !"ADMIN".equalsIgnoreCase(user.getRole())) {
            throw BizException.forbidden(ErrorCode.ADMIN_FORBIDDEN);
        }

        UserContext.set(user.getId());
        touchLastActive(user);
        return true;
    }

    /**
     * 请求结束后清理 ThreadLocal。
     *
     * <p>漏掉这一步会导致线程复用时的用户身份串号 —— 严重的越权问题。
     */
    @Override
    public void afterCompletion(HttpServletRequest request,
                                HttpServletResponse response,
                                Object handler,
                                Exception ex) {
        UserContext.clear();
    }

    /** 是否请求的是管理端接口（登录接口已在 WebConfig 里排除）。 */
    private boolean isAdminPath(HttpServletRequest request) {
        String uri = request.getRequestURI();
        return uri != null && (uri.equals("/api/admin") || uri.startsWith("/api/admin/"));
    }

    /**
     * 节流更新「最近活跃时间」。
     *
     * <p>每个请求都写库会把数据库打满，所以同一用户 5 分钟内只写一次。
     * 管理端「用户管理」页的「最近活跃」列就靠它。
     */
    private void touchLastActive(User user) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime last = user.getLastActiveAt();
        if (last != null
                && Duration.between(last, now).toMinutes() < LAST_ACTIVE_THROTTLE_MINUTES) {
            return;
        }
        user.setLastActiveAt(now);
        userRepository.save(user);
    }

    /** 从请求头里取出 Bearer 令牌。 */
    private String extractToken(HttpServletRequest request) {
        String header = request.getHeader(AUTH_HEADER);
        if (header == null || !header.startsWith(BEARER_PREFIX)) {
            return null;
        }
        return header.substring(BEARER_PREFIX.length()).trim();
    }

    /** 启动时提醒开发令牌的风险。 */
    @jakarta.annotation.PostConstruct
    void warnAboutDevToken() {
        if (devTokenEnabled) {
            log.warn("══════════════════════════════════════════════════════════");
            log.warn("  开发令牌已启用：{}", devToken);
            log.warn("  它会被直接映射为账号 '{}'，无需登录即可调用所有接口。", devUsername);
            log.warn("  【交付/上线前请把 opc.security.dev-token-enabled 改为 false】");
            log.warn("══════════════════════════════════════════════════════════");
        }
    }
}
