package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.appartement.TypeLogement;
import com.tmk.immobilier.application.domain.locataire.ComptesSituations;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.domain.locataire.LocataireResume;
import com.tmk.immobilier.application.domain.locataire.SituationLocataire;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.LocataireJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.LocataireSpecs;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.LocatairePersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class LocataireRepositoryAdapter implements LocataireRepository {

    private static final Sort TRI = Sort.by("nom", "prenom");

    private final LocataireJpaRepository jpaRepository;
    private final LocatairePersistenceMapper mapper;
    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public Locataire save(Locataire locataire) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(locataire)));
    }

    @Override
    public Optional<Locataire> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public PageResult<Locataire> findPage(String recherche, int page, int size) {
        return PageResults.of(jpaRepository.findAll(LocataireSpecs.recherche(recherche),
                PageRequest.of(page, size, TRI)), mapper::toDomain);
    }

    @Override
    public PageResult<LocataireResume> findResumes(String recherche, SituationLocataire situation,
                                                   LocalDate aujourdhui, int page, int size) {
        boolean avecRecherche = LocataireResumeQueries.aRecherche(recherche);
        MapSqlParameterSource params = LocataireResumeQueries.parametres(recherche, situation, aujourdhui);
        Long total = jdbc.queryForObject(
                LocataireResumeQueries.total(avecRecherche, situation != null), params, Long.class);

        params.addValue("size", size).addValue("offset", (long) page * size);
        List<LigneResume> lignes = jdbc.query(LocataireResumeQueries.page(avecRecherche, situation != null), params,
                (rs, i) -> new LigneResume(
                        rs.getLong("id"),
                        SituationLocataire.valueOf(rs.getString("situation")),
                        rs.getInt("baux_actifs"),
                        rs.getInt("contrats_a_signer"),
                        rs.getBigDecimal("montant_retard"),
                        rs.getDate("plus_ancien_retard"),
                        rs.getString("logement_reference"),
                        rs.getString("logement_type"),
                        rs.getString("immeuble_nom")));

        Map<Long, Locataire> locataires = jpaRepository.findAllById(lignes.stream().map(LigneResume::id).toList())
                .stream().map(mapper::toDomain)
                .collect(Collectors.toMap(Locataire::getId, Function.identity()));
        List<LocataireResume> contenu = lignes.stream()
                .filter(l -> locataires.containsKey(l.id()))
                .map(l -> l.versResume(locataires.get(l.id()), aujourdhui))
                .toList();
        return new PageResult<>(contenu, page, size, total != null ? total : 0);
    }

    @Override
    public ComptesSituations compterSituations(String recherche, LocalDate aujourdhui) {
        boolean avecRecherche = LocataireResumeQueries.aRecherche(recherche);
        Map<String, Long> comptes = jdbc.query(LocataireResumeQueries.comptes(avecRecherche),
                        LocataireResumeQueries.parametres(recherche, null, aujourdhui),
                        (rs, i) -> Map.entry(rs.getString("situation"), rs.getLong("nombre")))
                .stream().collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
        return new ComptesSituations(
                comptes.getOrDefault(SituationLocataire.EN_RETARD.name(), 0L),
                comptes.getOrDefault(SituationLocataire.A_JOUR.name(), 0L),
                comptes.getOrDefault(SituationLocataire.SANS_BAIL.name(), 0L));
    }

    @Override
    public boolean existsByTelephone(String telephone) {
        return jpaRepository.existsByTelephone(telephone);
    }

    @Override
    public boolean existsByTelephoneAndIdNot(String telephone, Long id) {
        return jpaRepository.existsByTelephoneAndIdNot(telephone, id);
    }

    @Override
    public void deleteById(Long id) {
        jpaRepository.deleteById(id);
    }

    private record LigneResume(Long id, SituationLocataire situation, int bauxActifs, int contratsASigner,
                               BigDecimal montantRetard, Date plusAncienRetard, String logementReference,
                               String logementType, String immeubleNom) {

        LocataireResume versResume(Locataire locataire, LocalDate aujourdhui) {
            int jours = plusAncienRetard == null ? 0
                    : (int) ChronoUnit.DAYS.between(plusAncienRetard.toLocalDate(), aujourdhui);
            return new LocataireResume(locataire, situation, bauxActifs, logementReference, immeubleNom,
                    logementType != null ? TypeLogement.valueOf(logementType) : null,
                    montantRetard != null ? montantRetard : BigDecimal.ZERO, jours, contratsASigner);
        }
    }
}
