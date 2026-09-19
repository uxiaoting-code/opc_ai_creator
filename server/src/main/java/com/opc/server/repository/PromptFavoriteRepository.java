package com.opc.server.repository;

import com.opc.server.entity.PromptFavorite;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PromptFavoriteRepository extends JpaRepository<PromptFavorite, Long> {

    Optional<PromptFavorite> findByUserIdAndPromptId(Long userId, Long promptId);

    /** 判断「我是否已收藏」，配合唯一索引走索引查询，很快。 */
    boolean existsByUserIdAndPromptId(Long userId, Long promptId);

    Page<PromptFavorite> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    int deleteByUserIdAndPromptId(Long userId, Long promptId);

    long countByPromptId(Long promptId);
}
