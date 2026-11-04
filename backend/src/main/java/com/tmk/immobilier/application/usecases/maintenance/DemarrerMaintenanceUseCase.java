package com.tmk.immobilier.application.usecases.maintenance;

import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class DemarrerMaintenanceUseCase {

    private final MaintenanceRepository maintenanceRepository;

    @Transactional
    public Maintenance execute(Long id) {
        Maintenance maintenance = maintenanceRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Maintenance", id));
        maintenance.demarrer();
        return maintenanceRepository.save(maintenance);
    }
}
