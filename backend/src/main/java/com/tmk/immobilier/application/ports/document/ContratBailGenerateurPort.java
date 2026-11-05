package com.tmk.immobilier.application.ports.document;

import com.tmk.immobilier.application.domain.bail.Bail;

/** Met en page le contrat d'un bail, prêt à imprimer et à faire signer. */
public interface ContratBailGenerateurPort {

    /** @return le contrat au format PDF */
    byte[] generer(Bail bail);
}
