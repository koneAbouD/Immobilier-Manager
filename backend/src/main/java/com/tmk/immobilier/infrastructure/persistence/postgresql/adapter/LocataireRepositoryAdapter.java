package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.LocataireJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.LocataireSpecs;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.LocatairePersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
@RequiredArgsConstructor
public class LocataireRepositoryAdapter implements LocataireRepository {

    private static final Sort TRI = Sort.by("nom", "prenom");

    private final LocataireJpaRepository jpaRepository;
    private final LocatairePersistenceMapper mapper;

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
}
