package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.domain.immeuble.OccupationImmeuble;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public interface AppartementRepository {

    Appartement save(Appartement appartement);

    Optional<Appartement> findById(Long id);

    List<Appartement> findByImmeubleId(Long immeubleId);

    /** @param recherche mot-clé libre (référence, nom de l'immeuble) ; ignoré s'il est vide */
    PageResult<Appartement> findPage(Long immeubleId, StatutAppartement statut, String recherche, int page, int size);

    boolean existsByImmeubleIdAndReferenceIgnoreCase(Long immeubleId, String reference);

    boolean existsByImmeubleIdAndReferenceIgnoreCaseAndIdNot(Long immeubleId, String reference, Long id);

    boolean existsByImmeubleId(Long immeubleId);

    /** Occupation de chaque immeuble demandé, en une seule requête. */
    Map<Long, OccupationImmeuble> occupationParImmeuble(Collection<Long> immeubleIds);

    long count();

    long countByStatut(StatutAppartement statut);

    void deleteById(Long id);
}
