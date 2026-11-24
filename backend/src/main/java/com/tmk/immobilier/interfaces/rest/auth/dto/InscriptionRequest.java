package com.tmk.immobilier.interfaces.rest.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record InscriptionRequest(
        @NotBlank(message = "Le nom de l'organisation est obligatoire.")
        @Size(max = 150, message = "Le nom de l'organisation compte au plus 150 caractères.")
        String organisation,
        @NotBlank(message = "Le prénom est obligatoire.") @Size(max = 100) String prenom,
        @NotBlank(message = "Le nom est obligatoire.") @Size(max = 100) String nom,
        /** Facultatif. */
        @Email(message = "L'adresse e-mail n'est pas valide.") @Size(max = 150)
        String email,
        /** Identifiant de connexion. */
        @NotBlank(message = "Le numéro de téléphone est obligatoire.") @Size(max = 30)
        String telephone,
        @NotBlank(message = "Le mot de passe est obligatoire.")
        @Size(min = 8, max = 128, message = "Le mot de passe doit compter au moins 8 caractères.")
        String motDePasse
) {
}
