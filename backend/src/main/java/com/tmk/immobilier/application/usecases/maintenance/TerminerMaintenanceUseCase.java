package com.tmk.immobilier.application.usecases.maintenance;

import com.tmk.immobilier.application.usecases.journal.JournalActions;
import com.tmk.immobilier.application.usecases.journal.InstantanesMetier;
import com.tmk.immobilier.application.domain.journal.Instantane;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;

@RequiredArgsConstructor
public class TerminerMaintenanceUseCase {

    private final MaintenanceRepository maintenanceRepository;
    private final JournalActions journal;

    @Transactional
    public Maintenance execute(Long id, BigDecimal coutReel, LocalDate dateRealisation) {
        Maintenance maintenance = maintenanceRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Maintenance", id));
        if (dateRealisation != null && dateRealisation.isAfter(LocalDate.now())) {
            throw new RegleMetierException("DATE_REALISATION_FUTURE",
                    "Une intervention ne peut pas être terminée à une date future.");
        }
        Instantane avant = InstantanesMetier.de(maintenance);
        maintenance.terminer(coutReel, dateRealisation);
        Maintenance enregistree = maintenanceRepository.save(maintenance);
        journal.modification(TypeEntite.TRAVAUX, id, maintenance.getTitre(), InstantanesMetier.lieu(maintenance),
                avant, InstantanesMetier.de(maintenance));
        return enregistree;
    }
}
