package com.tmk.immobilier.application.usecases.maintenance;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.application.domain.maintenance.PrioriteMaintenance;
import com.tmk.immobilier.application.domain.maintenance.StatutMaintenance;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class GetMaintenancesUseCase {

    private final MaintenanceRepository maintenanceRepository;

    @Transactional(readOnly = true)
    public PageResult<Maintenance> executePage(Long immeubleId, Long appartementId, StatutMaintenance statut,
                                               PrioriteMaintenance priorite, String recherche, int page, int size) {
        return maintenanceRepository.findPage(immeubleId, appartementId, statut, priorite, recherche, page, size);
    }

    @Transactional(readOnly = true)
    public Maintenance executeById(Long id) {
        return maintenanceRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Maintenance", id));
    }
}
