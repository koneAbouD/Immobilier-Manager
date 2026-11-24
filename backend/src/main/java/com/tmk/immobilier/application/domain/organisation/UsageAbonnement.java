package com.tmk.immobilier.application.domain.organisation;

/** Consommation de l'organisation face aux limites de sa formule. */
public record UsageAbonnement(long biens, long lots, long membres) {
}
