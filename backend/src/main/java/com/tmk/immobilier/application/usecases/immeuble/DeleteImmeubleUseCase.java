package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.immeuble.PhotoBien;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import com.tmk.immobilier.application.ports.persistence.PhotoBienRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Supprime un immeuble saisi par erreur. Refusé dès qu'il porte des logements
 * ou un historique d'interventions : ces données perdraient leur rattachement.
 */
@RequiredArgsConstructor
public class DeleteImmeubleUseCase {

    private final ImmeubleRepository immeubleRepository;
    private final AppartementRepository appartementRepository;
    private final MaintenanceRepository maintenanceRepository;
    private final BailRepository bailRepository;
    private final PhotoBienRepository photoBienRepository;
    private final StockageDocumentsPort stockage;

    @Transactional
    public void execute(Long id) {
        Immeuble immeuble = immeubleRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Immeuble", id));
        if (immeuble.estTerrain()) supprimerLocalDuTerrain(id);
        if (appartementRepository.existsByImmeubleId(id)) {
            throw new RegleMetierException("IMMEUBLE_NON_VIDE",
                    "Cet immeuble contient des logements : supprimez-les d'abord.");
        }
        if (maintenanceRepository.existsByImmeubleId(id)) {
            throw new RegleMetierException("IMMEUBLE_AVEC_HISTORIQUE",
                    "Cet immeuble a un historique de maintenances : il ne peut pas être supprimé.");
        }
        // Les lignes de photos partent en cascade avec le bien ; leurs fichiers,
        // non : on les retire du stockage une fois le bien supprimé.
        List<PhotoBien> photos = photoBienRepository.findByImmeubleId(id);
        immeubleRepository.deleteById(id);
        photos.forEach(p -> stockage.supprimer(p.getCle()));
    }

    /** Le local automatique d'un terrain part avec lui, s'il n'a jamais été loué. */
    private void supprimerLocalDuTerrain(Long immeubleId) {
        for (Appartement local : appartementRepository.findByImmeubleId(immeubleId)) {
            if (bailRepository.existsByAppartementId(local.getId())) {
                throw new RegleMetierException("TERRAIN_AVEC_BAIL",
                        "Ce terrain a un historique de baux : il ne peut pas être supprimé.");
            }
            if (maintenanceRepository.existsByAppartementId(local.getId())) {
                throw new RegleMetierException("IMMEUBLE_AVEC_HISTORIQUE",
                        "Ce terrain a un historique de maintenances : il ne peut pas être supprimé.");
            }
            appartementRepository.deleteById(local.getId());
        }
    }
}
