package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;

import java.util.List;
import java.util.Optional;

public interface ImmeubleRepository {

    Immeuble save(Immeuble immeuble);

    Optional<Immeuble> findById(Long id);

    List<Immeuble> findAll();

    /** @param recherche mot-clé libre (nom, commune, ville) ; ignoré s'il est vide */
    PageResult<Immeuble> findPage(String recherche, int page, int size);

    boolean existsByNomIgnoreCase(String nom);

    boolean existsByNomIgnoreCaseAndIdNot(String nom, Long id);

    long count();

    void deleteById(Long id);
}
