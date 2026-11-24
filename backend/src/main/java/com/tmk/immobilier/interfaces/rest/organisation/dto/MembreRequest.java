package com.tmk.immobilier.interfaces.rest.organisation.dto;

import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record MembreRequest(
        @NotBlank(message = "L'adresse e-mail est obligatoire.")
        @Email(message = "L'adresse e-mail n'est pas valide.") @Size(max = 150) String email,
        @NotBlank(message = "Le prénom est obligatoire.") @Size(max = 100) String prenom,
        @NotBlank(message = "Le nom est obligatoire.") @Size(max = 100) String nom,
        @NotNull(message = "Le rôle est obligatoire.") RoleMembre role
) {
}
