package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.locataire.Locataire;

import java.util.Optional;

public interface LocataireRepository {

    Locataire save(Locataire locataire);

    Optional<Locataire> findById(Long id);

    /** @param recherche mot-clé libre (nom, prénom, téléphone) ; ignoré s'il est vide */
    PageResult<Locataire> findPage(String recherche, int page, int size);

    boolean existsByTelephone(String telephone);

    boolean existsByTelephoneAndIdNot(String telephone, Long id);

    void deleteById(Long id);
}
