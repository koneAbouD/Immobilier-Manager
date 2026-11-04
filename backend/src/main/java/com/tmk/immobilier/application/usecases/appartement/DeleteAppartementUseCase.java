package com.tmk.immobilier.application.usecases.appartement;

import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

/** Supprime un logement saisi par erreur, tant qu'aucun bail ni intervention ne s'y rattache. */
@RequiredArgsConstructor
public class DeleteAppartementUseCase {

    private final AppartementRepository appartementRepository;
    private final BailRepository bailRepository;
    private final MaintenanceRepository maintenanceRepository;

    @Transactional
    public void execute(Long id) {
        appartementRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Logement", id));
        if (bailRepository.existsByAppartementId(id)) {
            throw new RegleMetierException("APPARTEMENT_AVEC_BAIL",
                    "Ce logement a un historique de baux : il ne peut pas être supprimé.");
        }
        if (maintenanceRepository.existsByAppartementId(id)) {
            throw new RegleMetierException("APPARTEMENT_AVEC_HISTORIQUE",
                    "Ce logement a un historique de maintenances : il ne peut pas être supprimé.");
        }
        appartementRepository.deleteById(id);
    }
}
