package com.tmk.immobilier.application.domain.maintenance;

public enum StatutMaintenance {
    /** Problème remonté, pas encore programmé. */
    SIGNALEE,
    /** Date d'intervention fixée. */
    PLANIFIEE,
    EN_COURS,
    TERMINEE,
    ANNULEE;

    /** Vrai tant que l'intervention reste à mener. */
    public boolean estOuverte() {
        return this == SIGNALEE || this == PLANIFIEE || this == EN_COURS;
    }
}
