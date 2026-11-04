package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.StatutEcheance;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.EcheanceLoyerJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.EcheanceLoyerSpecs;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.EcheanceLoyerPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class EcheanceLoyerRepositoryAdapter implements EcheanceLoyerRepository {

    private static final List<StatutEcheance> NON_SOLDEES = List.of(StatutEcheance.A_PAYER, StatutEcheance.PARTIEL);
    private static final Sort TRI = Sort.by(Sort.Order.desc("periode"), Sort.Order.asc("dateEcheance"),
            Sort.Order.asc("id"));

    private final EcheanceLoyerJpaRepository jpaRepository;
    private final EcheanceLoyerPersistenceMapper mapper;

    @Override
    public EcheanceLoyer save(EcheanceLoyer echeance) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(echeance)));
    }

    @Override
    public List<EcheanceLoyer> saveAll(List<EcheanceLoyer> echeances) {
        return mapper.toDomainList(jpaRepository.saveAll(mapper.toEntityList(echeances)));
    }

    @Override
    public Optional<EcheanceLoyer> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public PageResult<EcheanceLoyer> findPage(Long bailId, Long locataireId, Long immeubleId, LocalDate periode,
                                              StatutEcheance statut, boolean aEncaisser, boolean enRetard,
                                              LocalDate aujourdhui,
                                              int page, int size) {
        return PageResults.of(jpaRepository.findAll(
                EcheanceLoyerSpecs.byFiltres(bailId, locataireId, immeubleId, periode, statut, aEncaisser,
                        enRetard, aujourdhui),
                PageRequest.of(page, size, TRI)), mapper::toDomain);
    }

    @Override
    public List<EcheanceLoyer> findByBailId(Long bailId) {
        return mapper.toDomainList(jpaRepository.findByBailIdOrderByPeriodeAsc(bailId));
    }

    @Override
    public boolean existsByBailIdAndPeriode(Long bailId, LocalDate periode) {
        return jpaRepository.existsByBailIdAndPeriode(bailId, periode);
    }

    @Override
    public BigDecimal sommeMontantDuPourPeriode(LocalDate periode) {
        return jpaRepository.sommeMontantDu(periode, StatutEcheance.ANNULEE);
    }

    @Override
    public BigDecimal sommeMontantPayePourPeriode(LocalDate periode) {
        return jpaRepository.sommeMontantPaye(periode, StatutEcheance.ANNULEE);
    }

    @Override
    public BigDecimal sommeImpayesAu(LocalDate aujourdhui) {
        return jpaRepository.sommeImpayes(NON_SOLDEES, aujourdhui);
    }

    @Override
    public long countEnRetardAu(LocalDate aujourdhui) {
        return jpaRepository.countByStatutInAndDateEcheanceBefore(NON_SOLDEES, aujourdhui);
    }
}
