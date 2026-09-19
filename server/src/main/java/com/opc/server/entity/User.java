package com.opc.server.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 用户，对应 {@code t_user}。
 */
@Entity
@Table(name = "t_user")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User extends BaseEntity {

    /** 登录账号，唯一 */
    @Column(name = "username", nullable = false, length = 50, unique = true)
    private String username;

    /**
     * 密码哈希。
     *
     * <p>存的是「盐$PBKDF2哈希」而不是明文，见 {@code PasswordEncoder}。
     * 加 {@code @JsonIgnore} 是双保险：万一哪天直接返回了实体，
     * 也不会把密码哈希泄露给前端。
     */
    @JsonIgnore
    @Column(name = "password", nullable = false, length = 200)
    private String password;

    /** 昵称，为空时前端回退显示 username */
    @Column(name = "nickname", length = 50)
    private String nickname;

    @Column(name = "avatar", length = 255)
    private String avatar;

    @Column(name = "email", length = 100)
    private String email;

    @Column(name = "phone", length = 20)
    private String phone;

    /** 角色：USER / ADMIN */
    @Column(name = "role", nullable = false, length = 20)
    @Builder.Default
    private String role = "USER";

    /** 剩余算力点，创建 AI 任务时扣减 */
    @Column(name = "credits", nullable = false)
    @Builder.Default
    private Integer credits = 200;

    /** 1 正常 / 0 禁用 */
    @Column(name = "status", nullable = false)
    @Builder.Default
    private Integer status = 1;

    /**
     * 逻辑删除：false 未删 / true 已删。
     *
     * <p>类型是 {@link Boolean} 而不是 {@code Integer}：数据库列仍是 {@code TINYINT}
     * （见 docs/schema.sql），JDBC 驱动会自动按「非 0 即 true」互转，
     * 但 Java 侧用布尔语义才能让 {@code ...AndDeletedFalse} 这类派生查询正常工作
     * —— 用 {@code Integer} 时 Hibernate 6 会把它翻译成
     * {@code u.deleted = false} 然后抛类型不匹配错误。
     */
    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;

    /** 能否扣费创建任务。 */
    public boolean canAfford(int cost) {
        return credits != null && credits >= cost;
    }

    /** 扣减算力点。 */
    public void deductCredits(int cost) {
        if (credits == null) {
            credits = 0;
        }
        credits = Math.max(0, credits - cost);
    }
}
