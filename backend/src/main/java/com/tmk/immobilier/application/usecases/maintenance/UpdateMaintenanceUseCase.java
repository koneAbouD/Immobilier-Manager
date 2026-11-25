package com.tmk.immobilier.application.usecases.maintenance;

import com.tmk.immobilier.application.usecases.journal.JournalActions;
import com.tmk.immobilier.application.usecases.journal.InstantanesMetier;
import com.tmk.immobilier.application.domain.journal.Instantane;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
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
    private final JournalActions journal;

    @Transactional
    public Maintenance execute(Long id, Long immeubleId, Long appartementId, Maintenance modifications) {
        Maintenance existante = maintenanceRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Maintenance", id));
        if (!existante.getStatut().estOuverte()) {
            throw new RegleMetierException("MAINTENANCE_CLOSE", "Une intervention close ne se modifie plus.");
        }
        Instantane avant = InstantanesMetier.de(existante);
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
        Maintenance enregistree = maintenanceRepository.save(existante);
        journal.modification(TypeEntite.TRAVAUX, id, existante.getTitre(), InstantanesMetier.lieu(existante),
                avant, InstantanesMetier.de(existante));
        return enregistree;
    }
}
