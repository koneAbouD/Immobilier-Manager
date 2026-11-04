package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface PaiementLoyerRepository {

    PaiementLoyer save(PaiementLoyer paiement);

    Optional<PaiementLoyer> findById(Long id);

    List<PaiementLoyer> findByEcheanceId(Long echeanceId);

    PageResult<PaiementLoyer> findPage(Long bailId, Long locataireId, LocalDate dateDebut, LocalDate dateFin,
                                       Boolean annule, int page, int size);
}
