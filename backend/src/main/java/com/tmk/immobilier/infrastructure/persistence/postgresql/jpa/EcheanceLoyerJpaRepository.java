package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.loyer.StatutEcheance;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.EcheanceLoyerEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;

@Repository
public interface EcheanceLoyerJpaRepository extends JpaRepository<EcheanceLoyerEntity, Long>,
        JpaSpecificationExecutor<EcheanceLoyerEntity> {

    @Override
    @EntityGraph(attributePaths = {"bail", "bail.locataire", "bail.appartement", "bail.appartement.immeuble"})
    Page<EcheanceLoyerEntity> findAll(Specification<EcheanceLoyerEntity> spec, Pageable pageable);

    List<EcheanceLoyerEntity> findByBailIdOrderByPeriodeAsc(Long bailId);

    boolean existsByBailIdAndPeriode(Long bailId, LocalDate periode);

    @Query("""
            select coalesce(sum(e.montantDu), 0) from EcheanceLoyerEntity e
            where e.periode = :periode and e.statut <> :exclu
            """)
    BigDecimal sommeMontantDu(@Param("periode") LocalDate periode, @Param("exclu") StatutEcheance exclu);

    @Query("""
            select coalesce(sum(e.montantPaye), 0) from EcheanceLoyerEntity e
            where e.periode = :periode and e.statut <> :exclu
            """)
    BigDecimal sommeMontantPaye(@Param("periode") LocalDate periode, @Param("exclu") StatutEcheance exclu);

    @Query("""
            select coalesce(sum(e.montantDu - e.montantPaye), 0) from EcheanceLoyerEntity e
            where e.statut in :ouverts and e.dateEcheance < :aujourdhui
            """)
    BigDecimal sommeImpayes(@Param("ouverts") Collection<StatutEcheance> ouverts,
                            @Param("aujourdhui") LocalDate aujourdhui);

    long countByStatutInAndDateEcheanceBefore(Collection<StatutEcheance> statuts, LocalDate date);
}
