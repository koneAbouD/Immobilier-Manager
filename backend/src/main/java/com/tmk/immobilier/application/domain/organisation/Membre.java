package com.tmk.immobilier.application.domain.organisation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** Adhésion d'un utilisateur à une organisation, avec son rôle. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Membre {

    private Long id;
    private Long organisationId;
    private Utilisateur utilisateur;
    private RoleMembre role;
    private boolean actif;
    /** Renseigné à la lecture. */
    private LocalDateTime ajouteLe;
    /** Renseigné à la lecture, par les requêtes qui joignent l'organisation. */
    private Organisation organisation;

    public boolean estProprietaire() {
        return role == RoleMembre.PROPRIETAIRE;
    }
}
