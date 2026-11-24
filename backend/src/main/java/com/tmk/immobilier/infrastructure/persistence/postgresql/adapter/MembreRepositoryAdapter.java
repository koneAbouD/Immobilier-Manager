package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.ports.persistence.MembreRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.MembreEntity;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.MembreJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.OrganisationJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.UtilisateurJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.OrganisationPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class MembreRepositoryAdapter implements MembreRepository {

    private final MembreJpaRepository jpaRepository;
    private final OrganisationJpaRepository organisationJpaRepository;
    private final UtilisateurJpaRepository utilisateurJpaRepository;
    private final OrganisationPersistenceMapper mapper;

    /**
     * Écrit immédiatement (flush) : l'index unique « un propriétaire par
     * organisation » doit voir les changements de rôle dans l'ordre où le use
     * case les fait, pas dans celui que choisirait Hibernate.
     */
    @Override
    public Membre save(Membre membre) {
        MembreEntity entity;
        if (membre.getId() == null) {
            entity = new MembreEntity();
            entity.setOrganisation(organisationJpaRepository.findById(membre.getOrganisationId()).orElseThrow());
            entity.setUtilisateur(utilisateurJpaRepository.findById(membre.getUtilisateur().getId()).orElseThrow());
        } else {
            entity = jpaRepository.findDetailById(membre.getId()).orElseThrow();
        }
        entity.setRole(membre.getRole());
        entity.setActif(membre.isActif());
        MembreEntity saved = jpaRepository.saveAndFlush(entity);
        return mapper.toDomain(jpaRepository.findDetailById(saved.getId()).orElseThrow());
    }

    @Override
    public Optional<Membre> findById(Long id) {
        return jpaRepository.findDetailById(id).map(mapper::toDomain);
    }

    @Override
    public List<Membre> findByUtilisateurId(Long utilisateurId) {
        return jpaRepository.findByUtilisateurId(utilisateurId).stream().map(mapper::toDomain)
                .collect(java.util.stream.Collectors.toCollection(java.util.ArrayList::new));
    }

    @Override
    public Optional<Membre> findByOrganisationIdAndUtilisateurId(Long organisationId, Long utilisateurId) {
        return jpaRepository.findByOrganisationIdAndUtilisateurId(organisationId, utilisateurId).map(mapper::toDomain);
    }

    @Override
    public List<Membre> findByOrganisationId(Long organisationId) {
        return jpaRepository.findByOrganisationId(organisationId).stream()
                .map(mapper::toDomain)
                // Du rôle le plus étendu au plus restreint ; ordre alphabétique conservé à rôle égal.
                .sorted(Comparator.comparing(Membre::getRole))
                .toList();
    }

    @Override
    public long countActifsByOrganisationId(Long organisationId) {
        return jpaRepository.countByOrganisationIdAndActifTrue(organisationId);
    }

    @Override
    public boolean existsByOrganisationIdAndRole(Long organisationId, RoleMembre role) {
        return jpaRepository.existsByOrganisationIdAndRole(organisationId, role);
    }

    @Override
    public void deleteById(Long id) {
        jpaRepository.deleteById(id);
        jpaRepository.flush();
    }
}
