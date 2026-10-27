package com.opc.server.repository;

import com.opc.server.entity.MaterialTag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface MaterialTagRepository extends JpaRepository<MaterialTag, Long> {

    List<MaterialTag> findAllByDeletedFalseOrderBySortOrderAscIdAsc();

    List<MaterialTag> findAllByIdInAndDeletedFalse(Collection<Long> ids);

    Optional<MaterialTag> findByIdAndDeletedFalse(Long id);

    long countByDeletedFalse();
}
