package com.opc.server.repository;

import com.opc.server.entity.Submission;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.entity.enums.ReviewStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SubmissionRepository extends JpaRepository<Submission, Long> {

    Optional<Submission> findByIdAndUserId(Long id, Long userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from Submission s where s.id = :id")
    Optional<Submission> findByIdForUpdate(@Param("id") Long id);

    boolean existsByOrderIdAndUserIdAndStatus(Long orderId, Long userId, ReviewStatus status);

    Optional<Submission> findTopByOrderIdAndUserIdOrderByVersionNoDesc(Long orderId, Long userId);

    Optional<Submission> findTopByOrderIdAndUserIdOrderBySubmittedAtDesc(Long orderId, Long userId);

    @Query("""
            select s from Submission s
             where s.userId = :userId
               and (:status is null or s.status = :status)
               and (:mediaType is null or s.mediaType = :mediaType)
             order by s.submittedAt desc, s.id desc
            """)
    Page<Submission> findMy(
            @Param("userId") Long userId,
            @Param("status") ReviewStatus status,
            @Param("mediaType") MediaType mediaType,
            Pageable pageable);
}