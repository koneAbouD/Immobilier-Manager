package com.tmk.immobilier.interfaces.rest.immeuble.dto.response;

public record ImmeubleResponse(
        Long id,
        String nom,
        String adresse,
        String commune,
        String ville,
        Integer nombreEtages,
        Integer anneeConstruction,
        String description,
        long nombreAppartements,
        long nombreOccupes,
        long nombreLibres
) {
}
