package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.BailEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BailJpaRepository extends JpaRepository<BailEntity, Long>, JpaSpecificationExecutor<BailEntity> {

    /** Logement, immeuble et locataire voyagent avec la page : la réponse les expose. */
    @Override
    @EntityGraph(attributePaths = {"appartement", "appartement.immeuble", "locataire"})
    Page<BailEntity> findAll(Specification<BailEntity> spec, Pageable pageable);

    @EntityGraph(attributePaths = {"appartement", "appartement.immeuble", "locataire"})
    List<BailEntity> findByStatut(StatutBail statut);

    @EntityGraph(attributePaths = {"appartement", "appartement.immeuble", "locataire"})
    List<BailEntity> findByLocataireIdOrderByDateDebutDesc(Long locataireId);

    boolean existsByAppartementIdAndStatut(Long appartementId, StatutBail statut);

    boolean existsByAppartementId(Long appartementId);

    boolean existsByLocataireId(Long locataireId);

    @Query("select count(distinct b.locataire.id) from BailEntity b where b.statut = :statut")
    long countLocatairesDistinctsByStatut(@Param("statut") StatutBail statut);
}
