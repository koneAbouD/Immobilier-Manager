package com.tmk.immobilier.interfaces.rest.loyer.dto.response;

import com.tmk.immobilier.application.domain.loyer.ModePaiement;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record PaiementResponse(
        Long id,
        Long echeanceId,
        LocalDate periode,
        String bailReference,
        String locataireNom,
        String appartementReference,
        String immeubleNom,
        BigDecimal montant,
        LocalDate datePaiement,
        ModePaiement modePaiement,
        String reference,
        String commentaire,
        boolean annule,
        String motifAnnulation,
        String annulePar,
        LocalDateTime annuleLe,
        String encaissePar
) {
}
