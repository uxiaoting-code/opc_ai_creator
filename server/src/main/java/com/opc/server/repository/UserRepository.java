package com.opc.server.repository;

import com.opc.server.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByUsernameAndDeletedFalse(String username);

    Optional<User> findByIdAndDeletedFalse(Long id);

    boolean existsByUsernameAndDeletedFalse(String username);

    long countByDeletedFalse();

    long countByDeletedFalseAndLastActiveAtAfter(LocalDateTime time);

    long countByDeletedFalseAndLastActiveAtBetween(LocalDateTime start, LocalDateTime end);

    @Query("select coalesce(sum(u.credits), 0) from User u where u.deleted = false")
    Long sumCredits();

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update User u set u.credits = u.credits + :credits where u.id = :userId and u.deleted = false")
    int addCredits(@Param("userId") Long userId, @Param("credits") int credits);

    /** 管理端：按用户名/邮箱搜索并按状态过滤。 */
    @Query("""
            select u from User u
             where u.deleted = false
               and (:keyword is null
                    or lower(u.username) like lower(concat('%', :keyword, '%'))
                    or lower(coalesce(u.email, '')) like lower(concat('%', :keyword, '%')))
               and (:status is null or u.status = :status)
             order by u.createdAt desc, u.id desc
            """)
    Page<User> searchAdminUsers(
            @Param("keyword") String keyword,
            @Param("status") Integer status,
            Pageable pageable);
}
