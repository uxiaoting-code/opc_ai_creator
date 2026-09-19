package com.opc.server.security;

import com.opc.server.common.BizException;
import com.opc.server.entity.User;
import com.opc.server.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

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

        // ---- 开发令牌：映射到演示账号 ----
        if (devTokenEnabled && devToken.equals(token)) {
            User demoUser = userRepository.findByUsernameAndDeletedFalse(devUsername)
                    .orElseThrow(() -> BizException.unauthorized(
                            "开发令牌对应的演示账号不存在，请先执行数据初始化"));
            UserContext.set(demoUser.getId());
            return true;
        }

        // ---- 正常令牌 ----
        Optional<Long> userId = tokenService.resolveUserId(token);
        if (userId.isEmpty()) {
            throw BizException.unauthorized("登录已过期，请重新登录");
        }

        UserContext.set(userId.get());
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
