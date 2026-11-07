package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.domain.immeuble.PhotoBien;
import com.tmk.immobilier.application.ports.persistence.PhotoBienRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.PhotoBienJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.PhotoBienPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class PhotoBienRepositoryAdapter implements PhotoBienRepository {

    private final PhotoBienJpaRepository jpaRepository;
    private final PhotoBienPersistenceMapper mapper;

    @Override
    public PhotoBien save(PhotoBien photo) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(photo)));
    }

    @Override
    public Optional<PhotoBien> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public List<PhotoBien> findByImmeubleId(Long immeubleId) {
        return jpaRepository.findByImmeubleIdOrderByIdAsc(immeubleId).stream().map(mapper::toDomain).toList();
    }

    @Override
    public long countByImmeubleId(Long immeubleId) {
        return jpaRepository.countByImmeubleId(immeubleId);
    }

    @Override
    public void deleteById(Long id) {
        jpaRepository.deleteById(id);
    }
}
