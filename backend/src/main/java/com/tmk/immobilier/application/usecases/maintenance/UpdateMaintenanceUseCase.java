package com.tmk.immobilier.application.usecases.maintenance;

import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

/**
 * Modifie le contenu d'une intervention encore ouverte. Le statut ne se change
 * pas ici : il suit les actions dédiées (démarrer, terminer, annuler).
 */
@RequiredArgsConstructor
public class UpdateMaintenanceUseCase {

    private final MaintenanceRepository maintenanceRepository;
    private final ImmeubleRepository immeubleRepository;
    private final AppartementRepository appartementRepository;

    @Transactional
    public Maintenance execute(Long id, Long immeubleId, Long appartementId, Maintenance modifications) {
        Maintenance existante = maintenanceRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Maintenance", id));
        if (!existante.getStatut().estOuverte()) {
            throw new RegleMetierException("MAINTENANCE_CLOSE", "Une intervention close ne se modifie plus.");
        }
        MaintenanceRattachement.rattacher(existante, immeubleId, appartementId,
                immeubleRepository, appartementRepository);
        existante.setTitre(modifications.getTitre());
        existante.setDescription(modifications.getDescription());
        existante.setCategorie(modifications.getCategorie());
        if (modifications.getPriorite() != null) existante.setPriorite(modifications.getPriorite());
        if (modifications.getDateSignalement() != null) existante.setDateSignalement(modifications.getDateSignalement());
        existante.setDatePrevue(modifications.getDatePrevue());
        existante.setPrestataire(modifications.getPrestataire());
        existante.setCoutEstime(modifications.getCoutEstime());
        existante.planifierSiDate();
        return maintenanceRepository.save(existante);
    }
}
