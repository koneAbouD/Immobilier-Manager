package com.tmk.immobilier.interfaces.rest.organisation.dto;

import com.tmk.immobilier.application.domain.organisation.Membre;

import java.time.LocalDateTime;

public record MembreResponse(
        Long id,
        Long utilisateurId,
        String email,
        String prenom,
        String nom,
        String role,
        boolean actif,
        LocalDateTime ajouteLe,
        LocalDateTime derniereConnexion,
        /** Renseigné une seule fois, à la création du compte : à transmettre à l'intéressé. */
        String motDePasseTemporaire
) {

    public static MembreResponse from(Membre m) {
        return from(m, null);
    }

    public static MembreResponse from(Membre m, String motDePasseTemporaire) {
        return new MembreResponse(m.getId(), m.getUtilisateur().getId(), m.getUtilisateur().getEmail(),
                m.getUtilisateur().getPrenom(), m.getUtilisateur().getNom(), m.getRole().name(), m.isActif(),
                m.getAjouteLe(), m.getUtilisateur().getDerniereConnexion(), motDePasseTemporaire);
    }
}
