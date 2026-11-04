package com.tmk.immobilier.interfaces.rest.appartement.dto.response;

import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.domain.appartement.TypeLogement;

import java.math.BigDecimal;

public record AppartementResponse(
        Long id,
        Long immeubleId,
        String immeubleNom,
        String reference,
        Integer etage,
        TypeLogement type,
        BigDecimal superficie,
        Integer nombrePieces,
        BigDecimal loyerMensuel,
        BigDecimal charges,
        StatutAppartement statut,
        String description
) {
}
