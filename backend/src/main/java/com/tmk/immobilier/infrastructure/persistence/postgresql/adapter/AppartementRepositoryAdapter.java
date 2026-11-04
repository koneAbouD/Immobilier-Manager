package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.domain.immeuble.OccupationImmeuble;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.AppartementJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.AppartementSpecs;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.AppartementPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class AppartementRepositoryAdapter implements AppartementRepository {

    private static final Sort TRI = Sort.by("immeuble.nom", "reference");

    private final AppartementJpaRepository jpaRepository;
    private final AppartementPersistenceMapper mapper;

    @Override
    public Appartement save(Appartement appartement) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(appartement)));
    }

    @Override
    public Optional<Appartement> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public List<Appartement> findByImmeubleId(Long immeubleId) {
        return mapper.toDomainList(jpaRepository.findByImmeubleIdOrderByReferenceAsc(immeubleId));
    }

    @Override
    public PageResult<Appartement> findPage(Long immeubleId, StatutAppartement statut, String recherche,
                                            int page, int size) {
        return PageResults.of(jpaRepository.findAll(AppartementSpecs.byFiltres(immeubleId, statut, recherche),
                PageRequest.of(page, size, TRI)), mapper::toDomain);
    }

    @Override
    public boolean existsByImmeubleIdAndReferenceIgnoreCase(Long immeubleId, String reference) {
        return jpaRepository.existsByImmeubleIdAndReferenceIgnoreCase(immeubleId, reference);
    }

    @Override
    public boolean existsByImmeubleIdAndReferenceIgnoreCaseAndIdNot(Long immeubleId, String reference, Long id) {
        return jpaRepository.existsByImmeubleIdAndReferenceIgnoreCaseAndIdNot(immeubleId, reference, id);
    }

    @Override
    public boolean existsByImmeubleId(Long immeubleId) {
        return jpaRepository.existsByImmeubleId(immeubleId);
    }

    @Override
    public Map<Long, OccupationImmeuble> occupationParImmeuble(Collection<Long> immeubleIds) {
        if (immeubleIds.isEmpty()) return Map.of();
        return jpaRepository.occupationParImmeuble(immeubleIds, StatutAppartement.OCCUPE, StatutAppartement.LIBRE)
                .stream()
                .collect(Collectors.toMap(
                        AppartementJpaRepository.OccupationRow::getImmeubleId,
                        r -> new OccupationImmeuble(r.getTotal(), nonNul(r.getOccupes()), nonNul(r.getLibres()))));
    }

    private static long nonNul(Long valeur) {
        return valeur != null ? valeur : 0;
    }

    @Override
    public long count() {
        return jpaRepository.count();
    }

    @Override
    public long countByStatut(StatutAppartement statut) {
        return jpaRepository.countByStatut(statut);
    }

    @Override
    public void deleteById(Long id) {
        jpaRepository.deleteById(id);
    }
}
