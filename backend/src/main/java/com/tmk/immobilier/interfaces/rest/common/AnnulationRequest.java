package com.tmk.immobilier.interfaces.rest.common;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Motif obligatoire de toute annulation : une annulation sans motif ne se distingue pas d'un oubli. */
public record AnnulationRequest(
        @NotBlank(message = "Le motif est obligatoire.")
        @Size(max = 1000, message = "Le motif ne doit pas dépasser 1000 caractères.")
        String motif
) {
}
