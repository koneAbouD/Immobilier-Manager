package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.application.domain.maintenance.PrioriteMaintenance;
import com.tmk.immobilier.application.domain.maintenance.StatutMaintenance;

import java.util.Collection;
import java.util.Optional;

public interface MaintenanceRepository {

    Maintenance save(Maintenance maintenance);

    Optional<Maintenance> findById(Long id);

    /** @param recherche mot-clé libre (titre, prestataire, référence du logement) ; ignoré s'il est vide */
    PageResult<Maintenance> findPage(Long immeubleId, Long appartementId, StatutMaintenance statut,
                                     PrioriteMaintenance priorite, String recherche, int page, int size);

    boolean existsByImmeubleId(Long immeubleId);

    boolean existsByAppartementId(Long appartementId);

    long countByStatutIn(Collection<StatutMaintenance> statuts);

    long countByStatutInAndPriorite(Collection<StatutMaintenance> statuts, PrioriteMaintenance priorite);

    void deleteById(Long id);
}
