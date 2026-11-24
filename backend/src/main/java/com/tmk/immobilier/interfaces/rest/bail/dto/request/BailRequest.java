package com.tmk.immobilier.interfaces.rest.bail.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.time.LocalDate;

public record BailRequest(
        @NotNull(message = "Le logement est obligatoire.") Long appartementId,
        @NotNull(message = "Le locataire est obligatoire.") Long locataireId,
        @NotNull(message = "La date de début est obligatoire.") LocalDate dateDebut,
        LocalDate dateFin,
        /** Facultatif : à défaut, le loyer affiché du logement. */
        @Positive(message = "Le loyer mensuel doit être strictement positif.") BigDecimal loyerMensuel,
        @PositiveOrZero(message = "Les charges ne peuvent pas être négatives.") BigDecimal charges,
        @PositiveOrZero(message = "Le dépôt de garantie ne peut pas être négatif.") BigDecimal depotGarantie,
        /** Si renseigné, le dépôt de garantie vaut ce nombre de mois × le loyer mensuel. Sans lui ni montant : 2 mois. */
        @Min(value = 0, message = "Le nombre de mois de caution doit être compris entre 0 et 24.")
        @Max(value = 24, message = "Le nombre de mois de caution doit être compris entre 0 et 24.")
        Integer moisCaution,
        /** Mois de loyer réglés à la signature : ils ne sont pas facturés. */
        @Min(value = 0, message = "Le nombre de mois d'avance doit être compris entre 0 et 24.")
        @Max(value = 24, message = "Le nombre de mois d'avance doit être compris entre 0 et 24.")
        Integer moisAvance,
        /** Facultatif : à défaut, calculé (mois suivant la création, après l'avance). Seul le mois compte. */
        LocalDate premierMoisFacture,
        @Min(value = 1, message = "Le jour d'échéance doit être compris entre 1 et 28.")
        @Max(value = 28, message = "Le jour d'échéance doit être compris entre 1 et 28.")
        Integer jourEcheance
) {
}
