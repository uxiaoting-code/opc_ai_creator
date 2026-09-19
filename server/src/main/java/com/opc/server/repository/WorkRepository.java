package com.opc.server.repository;

import com.opc.server.entity.Work;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface WorkRepository extends JpaRepository<Work, Long> {

    Page<Work> findByUserIdAndDeletedFalseOrderByCreatedAtDesc(Long userId, Pageable pageable);

    /** 画廊：只看已发布到公开画廊的作品。 */
    Page<Work> findByIsPublicTrueAndDeletedFalseOrderByCreatedAtDesc(Pageable pageable);

    Optional<Work> findByIdAndDeletedFalse(Long id);

    Optional<Work> findByIdAndUserIdAndDeletedFalse(Long id, Long userId);

    long countByUserIdAndDeletedFalse(Long userId);

    Optional<Work> findByTaskIdAndDeletedFalse(Long taskId);
}
