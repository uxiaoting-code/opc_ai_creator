package com.opc.server.repository;

import com.opc.server.entity.GatewayEndpoint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GatewayEndpointRepository extends JpaRepository<GatewayEndpoint, Long> {

    Optional<GatewayEndpoint> findByIdAndDeletedFalse(Long id);

    List<GatewayEndpoint> findAllByDeletedFalseOrderByIdAsc();

    boolean existsByMethodAndPathAndDeletedFalse(String method, String path);

    long countByDeletedFalse();
}
