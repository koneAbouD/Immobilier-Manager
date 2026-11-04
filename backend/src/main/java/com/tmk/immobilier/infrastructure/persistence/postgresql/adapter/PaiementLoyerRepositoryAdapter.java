package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;
import com.tmk.immobilier.application.ports.persistence.PaiementLoyerRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.PaiementLoyerJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.PaiementLoyerSpecs;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.PaiementLoyerPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class PaiementLoyerRepositoryAdapter implements PaiementLoyerRepository {

    private static final Sort TRI = Sort.by(Sort.Order.desc("datePaiement"), Sort.Order.desc("id"));

    private final PaiementLoyerJpaRepository jpaRepository;
    private final PaiementLoyerPersistenceMapper mapper;

    @Override
    public PaiementLoyer save(PaiementLoyer paiement) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(paiement)));
    }

    @Override
    public Optional<PaiementLoyer> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public List<PaiementLoyer> findByEcheanceId(Long echeanceId) {
        return mapper.toDomainList(jpaRepository.findByEcheanceIdOrderByDatePaiementDescIdDesc(echeanceId));
    }

    @Override
    public PageResult<PaiementLoyer> findPage(Long bailId, Long locataireId, LocalDate dateDebut, LocalDate dateFin,
                                              Boolean annule, int page, int size) {
        return PageResults.of(jpaRepository.findAll(
                PaiementLoyerSpecs.byFiltres(bailId, locataireId, dateDebut, dateFin, annule),
                PageRequest.of(page, size, TRI)), mapper::toDomain);
    }
}
