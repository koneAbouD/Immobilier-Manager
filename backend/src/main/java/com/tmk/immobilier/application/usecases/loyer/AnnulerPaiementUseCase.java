package com.tmk.immobilier.application.usecases.loyer;

import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import com.tmk.immobilier.application.ports.persistence.PaiementLoyerRepository;
import com.tmk.immobilier.application.ports.security.AuteurCourantPort;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

/** Annule un encaissement erroné : il reste tracé, et l'échéance redevient due d'autant. */
@RequiredArgsConstructor
public class AnnulerPaiementUseCase {

    private final PaiementLoyerRepository paiementLoyerRepository;
    private final EcheanceLoyerRepository echeanceLoyerRepository;
    private final AuteurCourantPort auteurCourant;

    @Transactional
    public PaiementLoyer execute(Long paiementId, String motif) {
        PaiementLoyer paiement = paiementLoyerRepository.findById(paiementId)
                .orElseThrow(() -> ResourceNotFoundException.of("Paiement", paiementId));
        paiement.annuler(motif, auteurCourant.auteur());

        EcheanceLoyer echeance = paiement.getEcheance();
        echeance.retirerPaiement(paiement.getMontant());
        paiement.setEcheance(echeanceLoyerRepository.save(echeance));

        return paiementLoyerRepository.save(paiement);
    }
}
