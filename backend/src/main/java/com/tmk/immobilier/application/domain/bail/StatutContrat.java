package com.tmk.immobilier.application.domain.bail;

/** Avancement du contrat écrit d'un bail. */
public enum StatutContrat {
    /** Le PDF n'a jamais été généré. */
    A_GENERER,
    /** Généré, en attente de l'exemplaire signé. */
    A_SIGNER,
    /** L'exemplaire signé est archivé. */
    SIGNE
}
