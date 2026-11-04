package com.tmk.immobilier.application.domain.immeuble;

/**
 * Taux de remplissage d'un immeuble à l'instant de la lecture. Les logements
 * en travaux ne sont ni occupés ni libres : ils ne se louent pas.
 */
public record OccupationImmeuble(long nombreAppartements, long nombreOccupes, long nombreLibres) {

    public static final OccupationImmeuble VIDE = new OccupationImmeuble(0, 0, 0);
}
