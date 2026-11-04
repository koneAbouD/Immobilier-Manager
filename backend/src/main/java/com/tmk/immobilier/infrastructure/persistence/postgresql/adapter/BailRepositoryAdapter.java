package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.BailJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.BailSpecs;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.BailPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class BailRepositoryAdapter implements BailRepository {

    private static final Sort TRI = Sort.by(Sort.Order.asc("statut"), Sort.Order.desc("dateDebut"));

    private final BailJpaRepository jpaRepository;
    private final BailPersistenceMapper mapper;

    @Override
    public Bail save(Bail bail) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(bail)));
    }

    @Override
    public Optional<Bail> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public PageResult<Bail> findPage(Long appartementId, Long locataireId, Long immeubleId, StatutBail statut,
                                     String recherche, int page, int size) {
        return PageResults.of(jpaRepository.findAll(
                BailSpecs.byFiltres(appartementId, locataireId, immeubleId, statut, recherche),
                PageRequest.of(page, size, TRI)), mapper::toDomain);
    }

    @Override
    public List<Bail> findByStatut(StatutBail statut) {
        return mapper.toDomainList(jpaRepository.findByStatut(statut));
    }

    @Override
    public List<Bail> findByLocataireId(Long locataireId) {
        return mapper.toDomainList(jpaRepository.findByLocataireIdOrderByDateDebutDesc(locataireId));
    }

    @Override
    public boolean existsByAppartementIdAndStatut(Long appartementId, StatutBail statut) {
        return jpaRepository.existsByAppartementIdAndStatut(appartementId, statut);
    }

    @Override
    public boolean existsByAppartementId(Long appartementId) {
        return jpaRepository.existsByAppartementId(appartementId);
    }

    @Override
    public boolean existsByLocataireId(Long locataireId) {
        return jpaRepository.existsByLocataireId(locataireId);
    }

    @Override
    public long countLocatairesActifs() {
        return jpaRepository.countLocatairesDistinctsByStatut(StatutBail.ACTIF);
    }
}
