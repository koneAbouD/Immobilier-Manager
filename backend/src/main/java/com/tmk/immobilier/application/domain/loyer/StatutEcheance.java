package com.tmk.immobilier.application.domain.loyer;

public enum StatutEcheance {
    A_PAYER,
    PARTIEL,
    PAYEE,
    /** Loyer qui n'est plus dû (bail résilié avant son exigibilité). */
    ANNULEE
}
