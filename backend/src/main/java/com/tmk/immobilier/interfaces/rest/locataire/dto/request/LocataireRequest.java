package com.tmk.immobilier.interfaces.rest.locataire.dto.request;

import com.tmk.immobilier.application.domain.locataire.TypePiece;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record LocataireRequest(
        @NotBlank(message = "Le nom est obligatoire.") @Size(max = 100) String nom,
        @NotBlank(message = "Le prénom est obligatoire.") @Size(max = 100) String prenom,
        @NotBlank(message = "Le téléphone est obligatoire.") @Size(max = 30) String telephone,
        @Email(message = "Adresse e-mail invalide.") @Size(max = 150) String email,
        TypePiece typePiece,
        @Size(max = 50) String numeroPiece,
        @Size(max = 100) String profession,
        @Past(message = "La date de naissance doit être dans le passé.") LocalDate dateNaissance,
        @Size(max = 255) String adresse,
        @Size(max = 150) String contactUrgenceNom,
        @Size(max = 30) String contactUrgenceTelephone
) {
}
