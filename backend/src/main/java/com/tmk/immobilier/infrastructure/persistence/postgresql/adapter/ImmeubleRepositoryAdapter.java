package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.ImmeubleJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.ImmeubleSpecs;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.ImmeublePersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class ImmeubleRepositoryAdapter implements ImmeubleRepository {

    private static final Sort TRI = Sort.by("nom");

    private final ImmeubleJpaRepository jpaRepository;
    private final ImmeublePersistenceMapper mapper;

    @Override
    public Immeuble save(Immeuble immeuble) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(immeuble)));
    }

    @Override
    public Optional<Immeuble> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public List<Immeuble> findAll() {
        return mapper.toDomainList(jpaRepository.findAll(TRI));
    }

    @Override
    public PageResult<Immeuble> findPage(String recherche, int page, int size) {
        return PageResults.of(jpaRepository.findAll(ImmeubleSpecs.recherche(recherche), PageRequest.of(page, size, TRI)),
                mapper::toDomain);
    }

    @Override
    public boolean existsByNomIgnoreCase(String nom) {
        return jpaRepository.existsByNomIgnoreCase(nom);
    }

    @Override
    public boolean existsByNomIgnoreCaseAndIdNot(String nom, Long id) {
        return jpaRepository.existsByNomIgnoreCaseAndIdNot(nom, id);
    }

    @Override
    public long count() {
        return jpaRepository.count();
    }

    @Override
    public void deleteById(Long id) {
        jpaRepository.deleteById(id);
    }
}
