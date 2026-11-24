package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.UtilisateurEntity;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.UtilisateurJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.OrganisationPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
@RequiredArgsConstructor
public class UtilisateurRepositoryAdapter implements UtilisateurRepository {

    private final UtilisateurJpaRepository jpaRepository;
    private final OrganisationPersistenceMapper mapper;

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
