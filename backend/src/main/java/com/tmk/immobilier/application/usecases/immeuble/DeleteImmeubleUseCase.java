package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

/**
 * Supprime un immeuble saisi par erreur. Refusé dès qu'il porte des logements
 * ou un historique d'interventions : ces données perdraient leur rattachement.
 */
@RequiredArgsConstructor
public class DeleteImmeubleUseCase {

    private final ImmeubleRepository immeubleRepository;
    private final AppartementRepository appartementRepository;
    private final MaintenanceRepository maintenanceRepository;

    @Transactional
    public void execute(Long id) {
        immeubleRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Immeuble", id));
        if (appartementRepository.existsByImmeubleId(id)) {
            throw new RegleMetierException("IMMEUBLE_NON_VIDE",
                    "Cet immeuble contient des logements : supprimez-les d'abord.");
        }
        if (maintenanceRepository.existsByImmeubleId(id)) {
            throw new RegleMetierException("IMMEUBLE_AVEC_HISTORIQUE",
                    "Cet immeuble a un historique de maintenances : il ne peut pas être supprimé.");
        }
        immeubleRepository.deleteById(id);
    }
}
