package com.tmk.immobilier.interfaces.rest.locataire.dto.response;

import com.tmk.immobilier.application.domain.locataire.TypePiece;

import java.time.LocalDate;

public record LocataireResponse(
        Long id,
        String nom,
        String prenom,
        String nomComplet,
        String telephone,
        String email,
        TypePiece typePiece,
        String numeroPiece,
        String profession,
        LocalDate dateNaissance,
        String adresse,
        String contactUrgenceNom,
        String contactUrgenceTelephone
) {
}
