package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.UtilisateurEntity;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.UtilisateurJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.OrganisationPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
@RequiredArgsConstructor
public class UtilisateurRepositoryAdapter implements UtilisateurRepository {

    private final UtilisateurJpaRepository jpaRepository;
    private final OrganisationPersistenceMapper mapper;
    private final NamedParameterJdbcTemplate jdbc;

    /** ON CONFLICT DO NOTHING : un doublon ne lève pas d'erreur, qui avorterait la transaction. */
    private static final String CREER_SI_ABSENT = """
            INSERT INTO utilisateurs (keycloak_id, email, prenom, nom, telephone, derniere_connexion,
                                      created_at, updated_at, created_by, updated_by)
            VALUES (:keycloakId, :email, :prenom, :nom, :telephone, :derniereConnexion,
                    now(), now(), :email, :email)
            ON CONFLICT DO NOTHING
            """;

    @Override
    public Utilisateur creerSiAbsent(Utilisateur utilisateur) {
        jdbc.update(CREER_SI_ABSENT, new MapSqlParameterSource()
                .addValue("keycloakId", utilisateur.getKeycloakId())
                .addValue("email", utilisateur.getEmail())
                .addValue("prenom", utilisateur.getPrenom())
                .addValue("nom", utilisateur.getNom())
                .addValue("telephone", utilisateur.getTelephone())
                .addValue("derniereConnexion", utilisateur.getDerniereConnexion()));
        return findByKeycloakId(utilisateur.getKeycloakId()).orElseThrow(() -> new IllegalStateException(
                "Compte " + utilisateur.getEmail() + " impossible à créer : adresse déjà liée à un autre compte"));
    }

    @Override
    public Utilisateur save(Utilisateur utilisateur) {
        UtilisateurEntity cible = utilisateur.getId() == null ? new UtilisateurEntity()
                : jpaRepository.findById(utilisateur.getId()).orElseThrow();
        return mapper.toDomain(jpaRepository.save(mapper.copier(utilisateur, cible)));
    }

    @Override
    public Optional<Utilisateur> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<Utilisateur> findByKeycloakId(String keycloakId) {
        return jpaRepository.findByKeycloakId(keycloakId).map(mapper::toDomain);
    }

    @Override
    public Optional<Utilisateur> findByEmail(String email) {
        return jpaRepository.findByEmailIgnoreCase(email.trim()).map(mapper::toDomain);
    }
}
