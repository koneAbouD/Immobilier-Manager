package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.maintenance.PrioriteMaintenance;
import com.tmk.immobilier.application.domain.maintenance.StatutMaintenance;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.MaintenanceEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Collection;

@Repository
public interface MaintenanceJpaRepository extends JpaRepository<MaintenanceEntity, Long>,
        JpaSpecificationExecutor<MaintenanceEntity> {

    @Override
    @EntityGraph(attributePaths = {"immeuble", "appartement"})
    Page<MaintenanceEntity> findAll(Specification<MaintenanceEntity> spec, Pageable pageable);

    boolean existsByImmeubleId(Long immeubleId);

    boolean existsByAppartementId(Long appartementId);

    long countByStatutIn(Collection<StatutMaintenance> statuts);

    long countByStatutInAndPriorite(Collection<StatutMaintenance> statuts, PrioriteMaintenance priorite);
}
