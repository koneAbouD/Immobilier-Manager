package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.domain.organisation.Utilisateur;

import java.util.Optional;

public interface UtilisateurRepository {

    Utilisateur save(Utilisateur utilisateur);

    Optional<Utilisateur> findById(Long id);

    Optional<Utilisateur> findByKeycloakId(String keycloakId);

    Optional<Utilisateur> findByEmail(String email);
}
