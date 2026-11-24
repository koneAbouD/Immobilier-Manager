package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.MembreEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MembreJpaRepository extends JpaRepository<MembreEntity, Long> {

    @Query("select m from MembreEntity m join fetch m.organisation join fetch m.utilisateur where m.id = :id")
    Optional<MembreEntity> findDetailById(@Param("id") Long id);

    @Query("select m from MembreEntity m join fetch m.organisation join fetch m.utilisateur "
            + "where m.utilisateur.id = :utilisateurId")
    List<MembreEntity> findByUtilisateurId(@Param("utilisateurId") Long utilisateurId);

    @Query("select m from MembreEntity m join fetch m.organisation join fetch m.utilisateur "
            + "where m.organisation.id = :organisationId and m.utilisateur.id = :utilisateurId")
    Optional<MembreEntity> findByOrganisationIdAndUtilisateurId(@Param("organisationId") Long organisationId,
                                                               @Param("utilisateurId") Long utilisateurId);

    @Query("select m from MembreEntity m join fetch m.organisation join fetch m.utilisateur u "
            + "where m.organisation.id = :organisationId order by lower(u.nom), lower(u.prenom), m.id")
    List<MembreEntity> findByOrganisationId(@Param("organisationId") Long organisationId);

    long countByOrganisationIdAndActifTrue(Long organisationId);

    boolean existsByOrganisationIdAndRole(Long organisationId, RoleMembre role);
}
