package com.tmk.immobilier.interfaces.rest.locataire.dto.response;

import com.tmk.immobilier.application.domain.appartement.TypeLogement;
import com.tmk.immobilier.application.domain.locataire.SituationLocataire;

import java.math.BigDecimal;

public record LocataireResumeResponse(
        Long id,
        String nom,
        String prenom,
        String nomComplet,
        String telephone,
        String profession,
        SituationLocataire situation,
        int nombreBauxActifs,
        String logementReference,
        String immeubleNom,
        TypeLogement typeLogement,
        BigDecimal montantEnRetard,
        int joursRetard,
        int contratsASigner
) {
}
