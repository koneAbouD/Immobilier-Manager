package com.tmk.immobilier.interfaces.rest.immeuble.dto.response;

import java.time.LocalDateTime;

public record PhotoBienResponse(
        Long id,
        String nom,
        String type,
        Long taille,
        LocalDateTime ajouteeLe,
        String ajouteePar
) {
}
