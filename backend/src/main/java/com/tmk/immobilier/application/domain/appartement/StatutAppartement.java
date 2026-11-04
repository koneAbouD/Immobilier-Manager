package com.tmk.immobilier.application.domain.appartement;

public enum StatutAppartement {
    /** Disponible à la location. */
    LIBRE,
    /** Un bail actif le couvre. Statut posé et levé par les baux uniquement. */
    OCCUPE,
    /** Retiré de la location le temps de travaux. */
    EN_TRAVAUX
}
