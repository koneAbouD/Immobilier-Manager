package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.StatutBail;

import java.util.List;
import java.util.Optional;

public interface BailRepository {

    Bail save(Bail bail);

    Optional<Bail> findById(Long id);

    PageResult<Bail> findPage(Long appartementId, Long locataireId, Long immeubleId, StatutBail statut,
                              String recherche, int page, int size);

    List<Bail> findByStatut(StatutBail statut);

    List<Bail> findByLocataireId(Long locataireId);

    boolean existsByAppartementIdAndStatut(Long appartementId, StatutBail statut);

    boolean existsByAppartementId(Long appartementId);

    boolean existsByLocataireId(Long locataireId);

    /** Nombre de locataires distincts ayant au moins un bail actif. */
    long countLocatairesActifs();
}
