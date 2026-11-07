package com.tmk.immobilier.interfaces.rest.immeuble.dto.request;

import com.tmk.immobilier.application.domain.immeuble.TypeBien;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record ImmeubleRequest(
        @NotBlank(message = "Le nom de l'immeuble est obligatoire.")
        @Size(max = 150, message = "Le nom ne doit pas dépasser 150 caractères.")
        String nom,
        /** Immeuble par défaut. */
        TypeBien type,
        @Size(max = 255) String adresse,
        @Size(max = 100) String commune,
        @Size(max = 100) String ville,
        @PositiveOrZero(message = "Le nombre d'étages ne peut pas être négatif.") Integer nombreEtages,
        @Min(value = 1800, message = "Année de construction invalide.")
        @Max(value = 2100, message = "Année de construction invalide.")
        Integer anneeConstruction,
        String description,
        @DecimalMin(value = "-90", message = "Latitude invalide.")
        @DecimalMax(value = "90", message = "Latitude invalide.")
        BigDecimal latitude,
        @DecimalMin(value = "-180", message = "Longitude invalide.")
        @DecimalMax(value = "180", message = "Longitude invalide.")
        BigDecimal longitude
) {
}
