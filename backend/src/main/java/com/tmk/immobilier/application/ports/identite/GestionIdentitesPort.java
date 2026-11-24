package com.tmk.immobilier.application.ports.identite;

import java.util.Optional;

/**
 * Comptes de connexion chez le fournisseur d'identité (Keycloak, via son API
 * d'administration). Seul le backend crée des comptes : l'inscription libre
 * est fermée côté Keycloak.
 */
public interface GestionIdentitesPort {

    /**
     * Crée un compte actif.
     *
     * @param identifiant identifiant de connexion (numéro de téléphone canonique, ou e-mail)
     * @param email       facultatif
     * @return l'identifiant technique du compte (« sub » des jetons)
     */
    String creerCompte(String identifiant, String email, String prenom, String nom, String motDePasse);

    Optional<String> trouverParEmail(String email);

    /** Compte dont l'identifiant de connexion est exactement [identifiant]. */
    Optional<String> trouverParIdentifiant(String identifiant);

    void definirMotDePasse(String identifiant, String motDePasse);

    /** Compensation d'une inscription avortée ; sans effet si le compte n'existe plus. */
    void supprimerCompte(String identifiant);
}
