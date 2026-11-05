package com.tmk.immobilier.application.domain.locataire;

/** Où en est un locataire vis-à-vis de ses loyers, pour le trier et le filtrer. */
public enum SituationLocataire {
    /** Au moins un loyer échu reste impayé. */
    EN_RETARD,
    /** Un bail en cours, aucun loyer échu impayé. */
    A_JOUR,
    /** Aucun bail en cours. */
    SANS_BAIL
}
