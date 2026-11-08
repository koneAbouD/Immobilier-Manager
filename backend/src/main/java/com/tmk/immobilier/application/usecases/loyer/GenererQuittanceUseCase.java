package com.tmk.immobilier.application.usecases.loyer;

import com.tmk.immobilier.application.common.DocumentFichier;
import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.QuittanceGenerateurPort;
import com.tmk.immobilier.application.ports.persistence.PaiementLoyerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayInputStream;

/**
 * Quittance d'un paiement, produite à la demande : elle n'est pas conservée,
 * le paiement fait foi. Un paiement annulé n'en délivre pas.
 */
@RequiredArgsConstructor
public class GenererQuittanceUseCase {

    private final PaiementLoyerRepository paiementRepository;
    private final QuittanceGenerateurPort generateur;

    @Transactional(readOnly = true)
    public DocumentFichier execute(Long paiementId) {
        PaiementLoyer paiement = paiementRepository.findById(paiementId)
                .orElseThrow(() -> ResourceNotFoundException.of("Paiement", paiementId));
        if (paiement.isAnnule()) {
            throw new RegleMetierException("PAIEMENT_ANNULE", "Ce paiement est annulé : il ne donne pas lieu à quittance.");
        }
        byte[] pdf = generateur.generer(paiement);
        return new DocumentFichier(numero(paiement) + ".pdf", "application/pdf", pdf.length, new ByteArrayInputStream(pdf));
    }

    /** « Quittance-Q-000042 » : le numéro dérive de celui du paiement. */
    public static String numero(PaiementLoyer paiement) {
        return String.format("Quittance-Q-%06d", paiement.getId());
    }
}
