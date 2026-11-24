package com.tmk.immobilier.application.ports.document;

import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;
import com.tmk.immobilier.application.domain.organisation.Organisation;

/** Met en page la quittance d'un paiement de loyer, à remettre au locataire. */
public interface QuittanceGenerateurPort {

    /** @return la quittance au format PDF */
    /** @param bailleur organisation qui délivre la quittance */
    byte[] generer(PaiementLoyer paiement, Organisation bailleur);
}
