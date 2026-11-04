package com.tmk.immobilier.application.usecases.maintenance;

import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.application.domain.maintenance.StatutMaintenance;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

/**
 * Supprime une demande saisie par erreur. Seule une intervention encore au
 * stade du signalement s'efface : au-delà, elle a une histoire et s'annule.
 */
@RequiredArgsConstructor
public class DeleteMaintenanceUseCase {

    private final MaintenanceRepository maintenanceRepository;

    @Transactional
    public void execute(Long id) {
        Maintenance maintenance = maintenanceRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Maintenance", id));
        if (maintenance.getStatut() != StatutMaintenance.SIGNALEE) {
            throw new RegleMetierException("MAINTENANCE_NON_SUPPRIMABLE",
                    "Seule une intervention simplement signalée peut être supprimée ; annulez-la plutôt.");
        }
        maintenanceRepository.deleteById(id);
    }
}
