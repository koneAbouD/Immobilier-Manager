package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.organisation.StatutAbonnement;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.OrganisationEntity;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrganisationJpaRepository extends JpaRepository<OrganisationEntity, Long>,
        JpaSpecificationExecutor<OrganisationEntity> {

    Optional<OrganisationEntity> findByHistoriqueTrue();

    @Query("select o.id from OrganisationEntity o where o.statutAbonnement <> :exclu order by o.id")
    List<Long> findIdsByStatutAbonnementNot(@Param("exclu") StatutAbonnement exclu);

    static Specification<OrganisationEntity> recherche(String recherche) {
        return (root, query, cb) -> SpecsUtils.estVide(recherche) ? cb.conjunction()
                : SpecsUtils.contientUnDe(cb, recherche, root.get("nom"), root.get("email"), root.get("telephone"));
    }
}
