package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;

import java.util.List;
import java.util.Optional;

/** Adhésions : table globale, toujours interrogée avec l'organisation explicite. */
public interface MembreRepository {

    Membre save(Membre membre);

    /**
     * Ajoute l'adhésion sauf si elle existe déjà (ou si elle violerait l'unicité
     * du propriétaire) ; idempotent face aux requêtes simultanées.
     * @return l'adhésion de l'utilisateur à l'organisation, si elle existe
     */
    Optional<Membre> ajouterSiAbsente(Membre membre);

    Optional<Membre> findById(Long id);

    /** Adhésions d'un utilisateur, organisation jointe. */
    List<Membre> findByUtilisateurId(Long utilisateurId);

    Optional<Membre> findByOrganisationIdAndUtilisateurId(Long organisationId, Long utilisateurId);

    /** Membres d'une organisation, utilisateur joint, du rôle le plus élevé au plus bas. */
    List<Membre> findByOrganisationId(Long organisationId);

    long countActifsByOrganisationId(Long organisationId);

    boolean existsByOrganisationIdAndRole(Long organisationId, RoleMembre role);

    void deleteById(Long id);
}
