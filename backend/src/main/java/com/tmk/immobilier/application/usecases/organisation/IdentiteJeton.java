package com.tmk.immobilier.application.usecases.organisation;

import java.util.Set;

/**
 * Ce que le jeton d'accès dit de l'appelant.
 *
 * @param rolesPlateforme rôles du realm (SUPER_ADMIN, et les rôles ADMIN /
 *                        GESTIONNAIRE d'avant le SaaS qui donnent accès à
 *                        l'organisation historique)
 */
public record IdentiteJeton(String keycloakId, String email, String prenom, String nom, Set<String> rolesPlateforme) {

    public static final String ROLE_SUPER_ADMIN = "SUPER_ADMIN";

    public boolean superAdmin() {
        return rolesPlateforme.contains(ROLE_SUPER_ADMIN);
    }
}
