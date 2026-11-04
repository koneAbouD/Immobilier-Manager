package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.AppartementEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface AppartementJpaRepository extends JpaRepository<AppartementEntity, Long>,
        JpaSpecificationExecutor<AppartementEntity> {

    /** L'immeuble voyage avec la page : la réponse expose son nom. */
    @Override
    @EntityGraph(attributePaths = {"immeuble"})
    Page<AppartementEntity> findAll(Specification<AppartementEntity> spec, Pageable pageable);

    @EntityGraph(attributePaths = {"immeuble"})
    List<AppartementEntity> findByImmeubleIdOrderByReferenceAsc(Long immeubleId);

    boolean existsByImmeubleIdAndReferenceIgnoreCase(Long immeubleId, String reference);

    boolean existsByImmeubleIdAndReferenceIgnoreCaseAndIdNot(Long immeubleId, String reference, Long id);

    boolean existsByImmeubleId(Long immeubleId);

    long countByStatut(StatutAppartement statut);

    /** Projection d'agrégat : une ligne par immeuble. */
    interface OccupationRow {
        Long getImmeubleId();

        Long getTotal();

        Long getOccupes();

        Long getLibres();
    }

    @Query("""
            select a.immeuble.id as immeubleId,
                   count(a) as total,
                   sum(case when a.statut = :occupe then 1 else 0 end) as occupes,
                   sum(case when a.statut = :libre then 1 else 0 end) as libres
            from AppartementEntity a
            where a.immeuble.id in :immeubleIds
            group by a.immeuble.id
            """)
    List<OccupationRow> occupationParImmeuble(@Param("immeubleIds") Collection<Long> immeubleIds,
                                              @Param("occupe") StatutAppartement occupe,
                                              @Param("libre") StatutAppartement libre);
}
