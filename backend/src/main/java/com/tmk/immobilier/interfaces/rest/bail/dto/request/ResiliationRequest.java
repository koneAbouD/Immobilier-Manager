package com.tmk.immobilier.interfaces.rest.bail.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record ResiliationRequest(
        /** Date d'effet ; à défaut, aujourd'hui. */
        LocalDate dateResiliation,
        @NotBlank(message = "Le motif de résiliation est obligatoire.")
        @Size(max = 1000, message = "Le motif ne doit pas dépasser 1000 caractères.")
        String motif
) {
}
