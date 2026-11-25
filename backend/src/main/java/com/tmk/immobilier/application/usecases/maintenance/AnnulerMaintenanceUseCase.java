package com.tmk.immobilier.application.usecases.maintenance;

import com.tmk.immobilier.application.usecases.journal.JournalActions;
import com.tmk.immobilier.application.usecases.journal.InstantanesMetier;
import com.tmk.immobilier.application.domain.journal.Instantane;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import com.tmk.immobilier.application.ports.security.AuteurCourantPort;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class AnnulerMaintenanceUseCase {

    private final MaintenanceRepository maintenanceRepository;
    private final JournalActions journal;
    private final AuteurCourantPort auteurCourant;

    @Transactional
    public Maintenance execute(Long id, String motif) {
        Maintenance maintenance = maintenanceRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Maintenance", id));
        Instantane avant = InstantanesMetier.de(maintenance);
        maintenance.annuler(motif, auteurCourant.auteur());
        Maintenance enregistree = maintenanceRepository.save(maintenance);
        journal.modification(TypeEntite.TRAVAUX, id, maintenance.getTitre(), InstantanesMetier.lieu(maintenance),
                avant, InstantanesMetier.de(maintenance));
        return enregistree;
    }
}
