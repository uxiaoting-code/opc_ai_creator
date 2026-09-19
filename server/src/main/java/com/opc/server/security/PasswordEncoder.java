package com.opc.server.security;

import org.springframework.stereotype.Component;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * 密码哈希器。
 *
 * <p>用 JDK 自带的 <b>PBKDF2-HMAC-SHA256</b>，不额外引依赖。
 * 存储格式：{@code 迭代次数$盐(Base64)$哈希(Base64)} —— 把迭代次数一起存进去，
 * 以后调高强度时老密码仍然能验证通过。
 *
 * <p>为什么不能用 MD5/SHA256 直接哈希：那是通用摘要算法，速度快意味着
 * 暴力破解也快，而且彩虹表一查就出来。PBKDF2 通过加盐 + 大量迭代
 * 让每次验证都要付出可观的计算成本，把破解成本抬高好几个数量级。
 *
 * <p>生产环境更推荐 BCrypt / Argon2（自带盐且内存硬），
 * 这里不引 spring-security-crypto 是为了减少依赖 ——
 * PBKDF2 同样是 NIST 认可的口令哈希算法，课设完全够用。
 */
@Component
public class PasswordEncoder {

    private static final String ALGORITHM = "PBKDF2WithHmacSHA256";

    /** 迭代次数。越高越安全也越慢，12 万次在安全性和登录体验间比较平衡。 */
    private static final int ITERATIONS = 120_000;

    private static final int KEY_LENGTH_BITS = 256;
    private static final int SALT_LENGTH_BYTES = 16;

    private final SecureRandom secureRandom = new SecureRandom();

    /** 生成密码哈希。每次调用都用新的随机盐，所以同一个密码两次结果不同。 */
    public String encode(String rawPassword) {
        byte[] salt = new byte[SALT_LENGTH_BYTES];
        secureRandom.nextBytes(salt);

        byte[] hash = pbkdf2(rawPassword.toCharArray(), salt, ITERATIONS);

        return "%d$%s$%s".formatted(
                ITERATIONS,
                Base64.getEncoder().encodeToString(salt),
                Base64.getEncoder().encodeToString(hash));
    }

    /**
     * 校验密码。
     *
     * <p>用 {@link MessageDigest#isEqual} 而不是 {@code Arrays.equals} 做比较：
     * 前者是<b>恒定时间</b>比较，不会因为「第几位开始不同」而提前返回，
     * 从而堵住时序攻击（通过测量响应时间逐位猜出哈希）。
     */
    public boolean matches(String rawPassword, String encodedPassword) {
        if (rawPassword == null || encodedPassword == null) {
            return false;
        }

        String[] parts = encodedPassword.split("\\$");
        if (parts.length != 3) {
            return false;
        }

        try {
            int iterations = Integer.parseInt(parts[0]);
            byte[] salt = Base64.getDecoder().decode(parts[1]);
            byte[] expected = Base64.getDecoder().decode(parts[2]);

            byte[] actual = pbkdf2(rawPassword.toCharArray(), salt, iterations);
            return MessageDigest.isEqual(expected, actual);
        } catch (Exception e) {
            // 存储格式损坏时返回 false，不要把异常抛给调用方
            return false;
        }
    }

    private byte[] pbkdf2(char[] password, byte[] salt, int iterations) {
        try {
            PBEKeySpec spec = new PBEKeySpec(password, salt, iterations, KEY_LENGTH_BITS);
            try {
                return SecretKeyFactory.getInstance(ALGORITHM).generateSecret(spec).getEncoded();
            } finally {
                // 用完立刻清掉密码副本，减少密码在内存中驻留的时间
                spec.clearPassword();
            }
        } catch (Exception e) {
            throw new IllegalStateException("密码哈希失败", e);
        }
    }
}
