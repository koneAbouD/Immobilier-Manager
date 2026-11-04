package com.tmk.immobilier.interfaces.rest.appartement.dto.request;

import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.domain.appartement.TypeLogement;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record AppartementRequest(
        /** Immeuble de rattachement ; ignoré en modification (un logement ne déménage pas). */
        @NotNull(message = "L'immeuble est obligatoire.") Long immeubleId,
        @NotBlank(message = "La référence du logement est obligatoire.")
        @Size(max = 50, message = "La référence ne doit pas dépasser 50 caractères.")
        String reference,
        Integer etage,
        @NotNull(message = "Le type de logement est obligatoire.") TypeLogement type,
        @PositiveOrZero(message = "La superficie ne peut pas être négative.") BigDecimal superficie,
        @PositiveOrZero(message = "Le nombre de pièces ne peut pas être négatif.") Integer nombrePieces,
        @NotNull(message = "Le loyer mensuel est obligatoire.")
        @Positive(message = "Le loyer mensuel doit être strictement positif.")
        BigDecimal loyerMensuel,
        @PositiveOrZero(message = "Les charges ne peuvent pas être négatives.") BigDecimal charges,
        /** LIBRE ou EN_TRAVAUX ; OCCUPE est géré par les baux. */
        StatutAppartement statut,
        String description
) {
}
