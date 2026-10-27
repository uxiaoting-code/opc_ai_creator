package com.opc.server.repository;

import com.opc.server.entity.MaterialCategory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MaterialCategoryRepository extends JpaRepository<MaterialCategory, Long> {

    List<MaterialCategory> findAllByDeletedFalseOrderBySortOrderAscIdAsc();

    Optional<MaterialCategory> findByIdAndDeletedFalse(Long id);

    long countByDeletedFalse();
}
