package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.UtilisateurEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UtilisateurJpaRepository extends JpaRepository<UtilisateurEntity, Long> {

    Optional<UtilisateurEntity> findByKeycloakId(String keycloakId);

    Optional<UtilisateurEntity> findByEmailIgnoreCase(String email);

    Optional<UtilisateurEntity> findByTelephone(String telephone);
}
