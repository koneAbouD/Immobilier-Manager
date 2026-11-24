package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.StatutAbonnement;
import com.tmk.immobilier.application.domain.organisation.UsageAbonnement;
import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.OrganisationEntity;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.OrganisationJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.OrganisationPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class OrganisationRepositoryAdapter implements OrganisationRepository {

    /**
     * Comptage direct en SQL, hors filtre Hibernate : la plateforme compare les
     * consommations de plusieurs organisations à la fois. Ne renvoie que des
     * nombres, jamais de données métier.
     */
    private static final String USAGES = """
            SELECT o.id,
                   (SELECT count(*) FROM immeubles i    WHERE i.organisation_id = o.id) AS biens,
                   (SELECT count(*) FROM appartements a WHERE a.organisation_id = o.id) AS lots,
                   (SELECT count(*) FROM membres m      WHERE m.organisation_id = o.id AND m.actif) AS membres
              FROM organisations o
             WHERE o.id IN (:ids)
            """;

    private final OrganisationJpaRepository jpaRepository;
    private final OrganisationPersistenceMapper mapper;
    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public Organisation save(Organisation organisation) {
        OrganisationEntity cible = organisation.getId() == null ? new OrganisationEntity()
                : jpaRepository.findById(organisation.getId()).orElseThrow();
        return mapper.toDomain(jpaRepository.save(mapper.copier(organisation, cible)));
    }

    @Override
    public Optional<Organisation> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<Organisation> findHistorique() {
        return jpaRepository.findByHistoriqueTrue().map(mapper::toDomain);
    }

    @Override
    public List<Long> findIdsActives() {
        return jpaRepository.findIdsByStatutAbonnementNot(StatutAbonnement.RESILIE);
    }

    @Override
    public PageResult<Organisation> findPage(String recherche, int page, int size) {
        return PageResults.of(jpaRepository.findAll(OrganisationJpaRepository.recherche(recherche),
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))), mapper::toDomain);
    }

    @Override
    public Map<Long, UsageAbonnement> usages(Collection<Long> organisationIds) {
        Map<Long, UsageAbonnement> usages = new HashMap<>();
        if (organisationIds.isEmpty()) return usages;
        jdbc.query(USAGES, new MapSqlParameterSource("ids", organisationIds), rs -> {
            usages.put(rs.getLong("id"),
                    new UsageAbonnement(rs.getLong("biens"), rs.getLong("lots"), rs.getLong("membres")));
        });
        return usages;
    }
}
