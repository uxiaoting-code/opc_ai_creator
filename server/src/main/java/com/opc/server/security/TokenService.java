package com.opc.server.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 登录令牌管理。
 *
 * <p>课设用**进程内 Map** 保存令牌：零依赖、零配置、重启即失效。
 *
 * <p>局限要说清楚：多实例部署时令牌不共享（用户在 A 实例登录、请求打到 B 实例会被判未登录），
 * 重启后所有人要重新登录。生产环境的做法是 JWT（无状态，自带签名和过期）
 * 或 Redis 集中存储。本类的接口签名就是照着这个方向设计的，
 * 换成 JWT 只需替换 {@link #issue} 和 {@link #resolveUserId} 两个方法，
 * 调用方（拦截器、AuthService）一行都不用改。
 */
@Service
public class TokenService {

    private static final Logger log = LoggerFactory.getLogger(TokenService.class);

    private final Map<String, TokenInfo> tokenStore = new ConcurrentHashMap<>();

    /** 令牌有效期（小时）。 */
    @Value("${opc.security.token-ttl-hours:168}")
    private long tokenTtlHours;

    /**
     * 签发令牌。
     *
     * @return 形如 {@code <uuid>} 的令牌串
     */
    public String issue(Long userId, String username) {
        String token = UUID.randomUUID().toString().replace("-", "");
        Instant expiresAt = Instant.now().plus(Duration.ofHours(tokenTtlHours));
        tokenStore.put(token, new TokenInfo(userId, username, expiresAt));
        log.debug("签发令牌 userId={} 有效期至 {}", userId, expiresAt);
        return token;
    }

    /**
     * 用令牌换用户 ID。
     *
     * <p>过期的令牌会被顺手删掉并返回空，这样过期清理不需要额外的定时任务。
     */
    public Optional<Long> resolveUserId(String token) {
        if (token == null || token.isBlank()) {
            return Optional.empty();
        }

        TokenInfo info = tokenStore.get(token);
        if (info == null) {
            return Optional.empty();
        }

        if (info.isExpired()) {
            tokenStore.remove(token);
            return Optional.empty();
        }

        return Optional.of(info.userId());
    }

    /** 退出登录时吊销令牌。 */
    public void revoke(String token) {
        if (token != null) {
            tokenStore.remove(token);
        }
    }

    /** 吊销某个用户的全部令牌（改密码、封号时用）。 */
    public void revokeAllOf(Long userId) {
        tokenStore.entrySet().removeIf(entry -> entry.getValue().userId().equals(userId));
    }

    public int activeTokenCount() {
        return tokenStore.size();
    }

    /**
     * 定时清理过期令牌，防止长期运行后 Map 无限膨胀。
     *
     * <p>虽然 {@link #resolveUserId} 会懒删除，但用户如果再也不来访问，
     * 那条记录就永远留着 —— 所以还是需要一个兜底的定期清理。
     */
    @Scheduled(fixedDelay = 3_600_000L)
    public void purgeExpired() {
        int before = tokenStore.size();
        tokenStore.entrySet().removeIf(entry -> entry.getValue().isExpired());
        int removed = before - tokenStore.size();
        if (removed > 0) {
            log.debug("清理过期令牌 {} 个，剩余 {}", removed, tokenStore.size());
        }
    }

    private record TokenInfo(Long userId, String username, Instant expiresAt) {
        boolean isExpired() {
            return Instant.now().isAfter(expiresAt);
        }
    }
}
