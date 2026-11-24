package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.domain.organisation.Utilisateur;

import java.util.Optional;

public interface UtilisateurRepository {

    Utilisateur save(Utilisateur utilisateur);

    /**
     * Crée le compte s'il n'existe pas encore (même identifiant Keycloak), sans
     * jamais échouer sur un doublon : plusieurs requêtes simultanées d'un même
     * utilisateur à sa première connexion obtiennent toutes la même ligne.
     */
    Utilisateur creerSiAbsent(Utilisateur utilisateur);

    Optional<Utilisateur> findById(Long id);

    Optional<Utilisateur> findByKeycloakId(String keycloakId);

    Optional<Utilisateur> findByEmail(String email);

    Optional<Utilisateur> findByTelephone(String telephone);
}
