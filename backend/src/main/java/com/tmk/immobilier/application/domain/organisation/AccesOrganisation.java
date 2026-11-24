package com.tmk.immobilier.application.domain.organisation;

/** Ce que l'état de l'abonnement permet aux membres de l'organisation. */
public enum AccesOrganisation {
    /** Lecture et écriture. */
    COMPLET,
    /** Consultation seule : essai terminé, abonnement échu ou suspendu. */
    LECTURE_SEULE,
    /** Aucun accès aux données. */
    BLOQUE
}
