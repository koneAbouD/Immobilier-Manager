package com.tmk.immobilier.application.usecases.bail;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.organisation.NumeroteurPort;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import com.tmk.immobilier.application.usecases.loyer.GenererEcheancesUseCase;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

/**
 * Signature d'un bail : le logement passe occupé et le premier mois facturé est
 * fixé — le mois suivant l'enregistrement au plus tôt, après les mois réglés
 * d'avance. Un gestionnaire peut l'imposer pour un cas particulier.
 */
@RequiredArgsConstructor
public class CreateBailUseCase {

    public static final String COMPTEUR_BAUX = "BAIL";

    private final BailRepository bailRepository;
    private final AppartementRepository appartementRepository;
    private final LocataireRepository locataireRepository;
    private final GenererEcheancesUseCase genererEcheancesUseCase;
    private final NumeroteurPort numeroteur;

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
        // Ni nombre de mois ni montant libre : la caution d'usage s'applique.
        if (bail.getMoisCaution() == null && bail.getDepotGarantie() == null) {
            bail.setMoisCaution(Bail.MOIS_CAUTION_PAR_DEFAUT);
        }
        bail.appliquerCaution();
        bail.initializeDefaults();
        if (bail.getPremierMoisFacture() == null) {
            bail.recalculerPremierMoisFacture();
        } else {
            bail.definirPremierMoisFacture(bail.getPremierMoisFacture());
        }
        bail.valider();

        appartement.occuper();
        appartementRepository.save(appartement);

        // Numérotation continue propre à l'organisation : BAIL-00001, BAIL-00002…
        bail.setReference(String.format("BAIL-%05d", numeroteur.prochain(COMPTEUR_BAUX)));
        Bail saved = bailRepository.save(bail);

        // Mêmes règles que l'émission automatique : le mois en cours attend le 25.
        genererEcheancesUseCase.executePourBail(saved, GenererEcheancesUseCase.dernierMoisEmis(LocalDate.now()));
        return saved;
    }
}
