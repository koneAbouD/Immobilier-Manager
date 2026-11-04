package com.tmk.immobilier.interfaces.rest.bail.dto.response;

import com.tmk.immobilier.application.domain.bail.StatutBail;

import java.math.BigDecimal;
import java.time.LocalDate;

public record BailResponse(
        Long id,
        String reference,
        Long appartementId,
        String appartementReference,
        Long immeubleId,
        String immeubleNom,
        Long locataireId,
        String locataireNom,
        String locataireTelephone,
        LocalDate dateDebut,
        LocalDate dateFin,
        BigDecimal loyerMensuel,
        BigDecimal charges,
        BigDecimal montantMensuel,
        BigDecimal depotGarantie,
        Integer jourEcheance,
        StatutBail statut,
        LocalDate dateResiliation,
        String motifResiliation,
        String resiliePar
) {
}
