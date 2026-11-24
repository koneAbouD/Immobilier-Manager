package com.tmk.immobilier.application.ports.organisation;

import com.tmk.immobilier.application.domain.organisation.RoleMembre;

import java.util.Optional;

/**
 * Organisation pour le compte de laquelle s'exécute le traitement en cours :
 * celle de la requête HTTP, ou celle que parcourt un traitement planifié.
 * Le cloisonnement des données est appliqué par la persistance ; les use cases
 * s'en servent pour ce qui sort de la base (clés de stockage, quotas, droits).
 */
public interface OrganisationCourantePort {

    /** @throws IllegalStateException hors de tout contexte d'organisation */
    Long id();

    /** Membre à l'origine de la requête ; vide pour un traitement planifié. */
    Optional<Long> utilisateurId();

    /** Rôle de l'appelant ; vide pour un traitement planifié. */
    Optional<RoleMembre> role();
}
