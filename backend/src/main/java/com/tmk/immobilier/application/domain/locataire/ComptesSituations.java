package com.tmk.immobilier.application.domain.locataire;

/** Nombre de locataires par situation, pour les filtres de la liste. */
public record ComptesSituations(long enRetard, long aJour, long sansBail) {

    public long total() {
        return enRetard + aJour + sansBail;
    }
}
