package com.tmk.immobilier.interfaces.rest.maintenance.dto.request;

import com.tmk.immobilier.application.domain.maintenance.CategorieMaintenance;
import com.tmk.immobilier.application.domain.maintenance.PrioriteMaintenance;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public record MaintenanceRequest(
        /** Facultatif si un logement est indiqué : son immeuble est alors repris. */
        Long immeubleId,
        /** Nul pour une intervention sur les parties communes. */
        Long appartementId,
        @NotBlank(message = "Le titre est obligatoire.")
        @Size(max = 150, message = "Le titre ne doit pas dépasser 150 caractères.")
        String titre,
        String description,
        @NotNull(message = "La catégorie est obligatoire.") CategorieMaintenance categorie,
        PrioriteMaintenance priorite,
        LocalDate dateSignalement,
        LocalDate datePrevue,
        @Size(max = 150) String prestataire,
        @PositiveOrZero(message = "Le coût estimé ne peut pas être négatif.") BigDecimal coutEstime
) {
}
