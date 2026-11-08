package com.tmk.immobilier.application.ports.document;

import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;

/** Met en page la quittance d'un paiement de loyer, à remettre au locataire. */
public interface QuittanceGenerateurPort {

    /** @return la quittance au format PDF */
    byte[] generer(PaiementLoyer paiement);
}
