package com.tmk.immobilier.application.ports.document;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.organisation.Organisation;

/** Met en page le contrat d'un bail, prêt à imprimer et à faire signer. */
public interface ContratBailGenerateurPort {

    /** @return le contrat au format PDF */
    /** @param bailleur organisation qui loue : identité, ville de signature, logo */
    byte[] generer(Bail bail, Organisation bailleur);
}
