package com.tmk.immobilier.interfaces.rest.loyer.dto.request;

import com.tmk.immobilier.application.domain.loyer.ModePaiement;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public record PaiementRequest(
        @NotNull(message = "Le montant est obligatoire.")
        @Positive(message = "Le montant doit être strictement positif.")
        BigDecimal montant,
        /** À défaut, aujourd'hui. */
        LocalDate datePaiement,
        @NotNull(message = "Le mode de paiement est obligatoire.") ModePaiement modePaiement,
        @Size(max = 100) String reference,
        String commentaire
) {
}
