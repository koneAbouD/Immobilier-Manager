package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.PaiementLoyerEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PaiementLoyerJpaRepository extends JpaRepository<PaiementLoyerEntity, Long>,
        JpaSpecificationExecutor<PaiementLoyerEntity> {

    @Override
    @EntityGraph(attributePaths = {"echeance", "echeance.bail", "echeance.bail.locataire",
            "echeance.bail.appartement", "echeance.bail.appartement.immeuble"})
    Page<PaiementLoyerEntity> findAll(Specification<PaiementLoyerEntity> spec, Pageable pageable);

    List<PaiementLoyerEntity> findByEcheanceIdOrderByDatePaiementDescIdDesc(Long echeanceId);
}
