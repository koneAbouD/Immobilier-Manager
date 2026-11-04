package com.tmk.immobilier.application.usecases.loyer;

import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import com.tmk.immobilier.application.ports.persistence.PaiementLoyerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

/**
 * Encaisse tout ou partie d'un loyer. Le paiement ne peut dépasser le reste
 * dû : un trop-perçu n'aurait pas d'échéance où se loger.
 */
@RequiredArgsConstructor
public class EnregistrerPaiementUseCase {

    private final EcheanceLoyerRepository echeanceLoyerRepository;
    private final PaiementLoyerRepository paiementLoyerRepository;

    @Transactional
    public PaiementLoyer execute(Long echeanceId, PaiementLoyer paiement) {
        EcheanceLoyer echeance = echeanceLoyerRepository.findById(echeanceId)
                .orElseThrow(() -> ResourceNotFoundException.of("Échéance de loyer", echeanceId));

        LocalDate date = paiement.getDatePaiement() != null ? paiement.getDatePaiement() : LocalDate.now();
        if (date.isAfter(LocalDate.now())) {
            throw new RegleMetierException("PAIEMENT_FUTUR", "Un paiement ne peut pas être daté dans le futur.");
        }

        echeance.enregistrerPaiement(paiement.getMontant());
        EcheanceLoyer echeanceMaj = echeanceLoyerRepository.save(echeance);

        paiement.setId(null);
        paiement.setAnnule(false);
        paiement.setDatePaiement(date);
        paiement.setEcheance(echeanceMaj);
        return paiementLoyerRepository.save(paiement);
    }
}
