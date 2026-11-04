package com.tmk.immobilier.interfaces.rest.loyer.dto.response;

import com.tmk.immobilier.application.domain.loyer.StatutEcheance;

import java.math.BigDecimal;
import java.time.LocalDate;

public record EcheanceResponse(
        Long id,
        Long bailId,
        String bailReference,
        Long locataireId,
        String locataireNom,
        String locataireTelephone,
        Long appartementId,
        String appartementReference,
        String immeubleNom,
        LocalDate periode,
        LocalDate dateEcheance,
        BigDecimal montantDu,
        BigDecimal montantPaye,
        BigDecimal resteDu,
        StatutEcheance statut,
        boolean enRetard
) {
}
