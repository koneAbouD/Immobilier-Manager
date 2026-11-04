package com.tmk.immobilier.interfaces.rest.bail.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Révision des conditions d'un bail actif ; le logement et le locataire ne changent pas. */
public record BailConditionsRequest(
        LocalDate dateDebut,
        LocalDate dateFin,
        @Positive(message = "Le loyer mensuel doit être strictement positif.") BigDecimal loyerMensuel,
        @PositiveOrZero(message = "Les charges ne peuvent pas être négatives.") BigDecimal charges,
        @PositiveOrZero(message = "Le dépôt de garantie ne peut pas être négatif.") BigDecimal depotGarantie,
        @Min(value = 1, message = "Le jour d'échéance doit être compris entre 1 et 28.")
        @Max(value = 28, message = "Le jour d'échéance doit être compris entre 1 et 28.")
        Integer jourEcheance
) {
}
