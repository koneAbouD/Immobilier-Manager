package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.usecases.journal.JournalActions;
import com.tmk.immobilier.application.usecases.journal.InstantanesMetier;
import com.tmk.immobilier.application.domain.journal.Instantane;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.commun.BlocageSuppression;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.immeuble.PhotoBien;
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
import java.util.Optional;

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
    private final JournalActions journal;

    /** Ce qui empêche de supprimer le bien, vide s'il peut l'être. */
    @Transactional(readOnly = true)
    public Optional<BlocageSuppression> blocage(Long id) {
        Immeuble immeuble = immeubleRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Immeuble", id));
        if (immeuble.estTerrain()) {
            // Le local automatique d'un terrain part avec lui, s'il n'a jamais servi.
            for (Appartement local : appartementRepository.findByImmeubleId(id)) {
                if (bailRepository.existsByAppartementId(local.getId())) {
                    return Optional.of(new BlocageSuppression("TERRAIN_AVEC_BAIL",
                            "Ce terrain a un historique de baux : il ne peut pas être supprimé."));
                }
                if (maintenanceRepository.existsByAppartementId(local.getId())) {
                    return Optional.of(new BlocageSuppression("IMMEUBLE_AVEC_HISTORIQUE",
                            "Ce terrain a un historique de maintenances : il ne peut pas être supprimé."));
                }
            }
        } else if (appartementRepository.existsByImmeubleId(id)) {
            return Optional.of(new BlocageSuppression("IMMEUBLE_NON_VIDE",
                    "Cet immeuble contient des logements : supprimez-les d'abord."));
        }
        if (maintenanceRepository.existsByImmeubleId(id)) {
            return Optional.of(new BlocageSuppression("IMMEUBLE_AVEC_HISTORIQUE",
                    "Cet immeuble a un historique de maintenances : il ne peut pas être supprimé."));
        }
        return Optional.empty();
    }

    @Transactional
    public void execute(Long id) {
        blocage(id).ifPresent(b -> { throw b.enException(); });
        Immeuble immeuble = immeubleRepository.findById(id).orElseThrow();
        journal.suppression(TypeEntite.BIEN, id, immeuble.getNom(), immeuble.getVille(), InstantanesMetier.de(immeuble));
        if (immeuble.estTerrain()) {
            appartementRepository.findByImmeubleId(id).forEach(local -> appartementRepository.deleteById(local.getId()));
        }
        // Les lignes de photos partent en cascade avec le bien ; leurs fichiers,
        // non : on les retire du stockage une fois le bien supprimé.
        List<PhotoBien> photos = photoBienRepository.findByImmeubleId(id);
        immeubleRepository.deleteById(id);
        photos.forEach(p -> stockage.supprimer(p.getCle()));
    }
}
