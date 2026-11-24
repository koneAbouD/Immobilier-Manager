package com.tmk.immobilier.application.domain.organisation;

public enum StatutAbonnement {
    /** Période d'essai gratuite, jusqu'à {@code essaiFinLe}. */
    ESSAI,
    /** Abonnement payé, jusqu'à {@code abonnementFinLe} (nulle = sans échéance). */
    ACTIF,
    /** Suspendu par la plateforme (impayé, abus) : consultation seule. */
    SUSPENDU,
    /** Compte clos : plus aucun accès. */
    RESILIE
}
