package com.tmk.immobilier.application.usecases.bail;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import com.tmk.immobilier.application.usecases.loyer.GenererEcheancesUseCase;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.YearMonth;

/**
 * Signature d'un bail : le logement passe occupé et les loyers dus depuis le
 * début du bail jusqu'au mois courant sont générés aussitôt — un bail saisi
 * avec retard rattrape ainsi ses échéances passées.
 */
@RequiredArgsConstructor
public class CreateBailUseCase {

    private final BailRepository bailRepository;
    private final AppartementRepository appartementRepository;
    private final LocataireRepository locataireRepository;
    private final GenererEcheancesUseCase genererEcheancesUseCase;

    @Transactional
    public Bail execute(Long appartementId, Long locataireId, Bail bail) {
        Appartement appartement = appartementRepository.findById(appartementId)
                .orElseThrow(() -> ResourceNotFoundException.of("Logement", appartementId));
        Locataire locataire = locataireRepository.findById(locataireId)
                .orElseThrow(() -> ResourceNotFoundException.of("Locataire", locataireId));

        if (bailRepository.existsByAppartementIdAndStatut(appartementId, StatutBail.ACTIF)) {
            throw new RegleMetierException("APPARTEMENT_DEJA_LOUE",
                    "Le logement " + appartement.getReference() + " a déjà un bail actif.");
        }

        // Sans conditions propres, le bail reprend celles affichées pour le logement.
        if (bail.getLoyerMensuel() == null) bail.setLoyerMensuel(appartement.getLoyerMensuel());
        if (bail.getCharges() == null) bail.setCharges(appartement.getCharges());

        bail.setId(null);
        bail.setStatut(StatutBail.ACTIF);
        bail.setAppartement(appartement);
        bail.setLocataire(locataire);
        bail.initializeDefaults();
        bail.valider();

        appartement.occuper();
        appartementRepository.save(appartement);

        Bail saved = bailRepository.save(bail);
        // La référence dérive de l'identifiant, connu seulement après insertion.
        saved.setReference(String.format("BAIL-%05d", saved.getId()));
        saved = bailRepository.save(saved);

        genererEcheancesUseCase.executePourBail(saved, YearMonth.now());
        return saved;
    }
}
