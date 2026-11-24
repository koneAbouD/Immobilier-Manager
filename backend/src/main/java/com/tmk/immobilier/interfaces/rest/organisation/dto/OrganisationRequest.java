package com.tmk.immobilier.interfaces.rest.organisation.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record OrganisationRequest(
        @NotBlank(message = "Le nom de l'organisation est obligatoire.") @Size(max = 150) String nom,
        @Size(max = 150) String representant,
        @Email(message = "L'adresse e-mail n'est pas valide.") @Size(max = 150) String email,
        @Size(max = 30) String telephone,
        @Size(max = 255) String adresse,
        @Size(max = 100) String ville,
        @Pattern(regexp = "^[A-Za-z]{2}$", message = "Le pays s'exprime en code ISO à 2 lettres (CI, SN…).") String pays,
        @Pattern(regexp = "^[A-Za-z]{3}$", message = "La devise s'exprime en code ISO à 3 lettres (XOF…).") String devise
) {
}
