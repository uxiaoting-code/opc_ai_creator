package com.opc.server.repository;

import com.opc.server.entity.Material;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MaterialRepository extends JpaRepository<Material, Long> {

    Page<Material> findByUserIdAndDeletedFalseOrderByCreatedAtDesc(Long userId, Pageable pageable);

    Page<Material> findByUserIdAndGroupNameAndDeletedFalseOrderByCreatedAtDesc(
            Long userId, String groupName, Pageable pageable);

    Optional<Material> findByIdAndUserIdAndDeletedFalse(Long id, Long userId);

    long countByUserIdAndDeletedFalse(Long userId);
}
