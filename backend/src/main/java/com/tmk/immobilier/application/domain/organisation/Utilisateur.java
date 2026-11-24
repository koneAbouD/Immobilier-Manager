package com.tmk.immobilier.application.domain.organisation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** Compte de connexion ; l'authentification elle-même est confiée à Keycloak. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Utilisateur {

    private Long id;
    /** Identifiant Keycloak (claim « sub » du jeton). */
    private String keycloakId;
    private String email;
    private String prenom;
    private String nom;
    private String telephone;
    private LocalDateTime derniereConnexion;

    public String nomComplet() {
        String complet = ((prenom != null ? prenom : "") + " " + (nom != null ? nom : "")).trim();
        return complet.isEmpty() ? email : complet;
    }
}
