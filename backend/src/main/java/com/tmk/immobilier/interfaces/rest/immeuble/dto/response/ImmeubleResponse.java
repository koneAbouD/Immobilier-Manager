package com.tmk.immobilier.interfaces.rest.immeuble.dto.response;

import com.tmk.immobilier.application.domain.immeuble.TypeBien;

import java.math.BigDecimal;

public record ImmeubleResponse(
        Long id,
        String nom,
        TypeBien type,
        String adresse,
        String commune,
        String ville,
        Integer nombreEtages,
        Integer anneeConstruction,
        String description,
        BigDecimal latitude,
        BigDecimal longitude,
        long nombreAppartements,
        long nombreOccupes,
        long nombreLibres
) {
}
