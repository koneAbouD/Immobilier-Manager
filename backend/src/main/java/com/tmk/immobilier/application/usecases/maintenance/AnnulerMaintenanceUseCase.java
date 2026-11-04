package com.tmk.immobilier.application.usecases.maintenance;

import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import com.tmk.immobilier.application.ports.security.AuteurCourantPort;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class AnnulerMaintenanceUseCase {

    private final MaintenanceRepository maintenanceRepository;
    private final AuteurCourantPort auteurCourant;

    @Transactional
    public Maintenance execute(Long id, String motif) {
        Maintenance maintenance = maintenanceRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Maintenance", id));
        maintenance.annuler(motif, auteurCourant.auteur());
        return maintenanceRepository.save(maintenance);
    }
}
