package com.tmk.immobilier.infrastructure.organisation;

import com.tmk.immobilier.application.domain.organisation.RoleMembre;

import java.util.Optional;
import java.util.function.Supplier;

/**
 * Organisation du traitement en cours, portée par le thread.
 *
 * <p>Posée par {@code ContexteOrganisationFilter} pour une requête HTTP, par
 * {@link #executerPour} pour un traitement planifié, et toujours effacée à la
 * fin : un thread recyclé du pool ne garde jamais l'organisation précédente.
 */
public final class ContexteOrganisation {

    /** Identifiant sentinelle hors contexte : ne correspond à aucune ligne, n'en crée aucune (clé étrangère). */
    public static final Long AUCUNE = -1L;

    public record Contexte(Long organisationId, Long utilisateurId, RoleMembre role) {
    }

    private static final ThreadLocal<Contexte> COURANT = new ThreadLocal<>();

    private ContexteOrganisation() {
    }

    public static Optional<Contexte> courant() {
        return Optional.ofNullable(COURANT.get());
    }

    public static Long organisationIdOuAucune() {
        Contexte contexte = COURANT.get();
        return contexte != null ? contexte.organisationId() : AUCUNE;
    }

    public static void definir(Contexte contexte) {
        COURANT.set(contexte);
    }

    public static void effacer() {
        COURANT.remove();
    }

    /** Exécute [action] pour le compte de l'organisation, sans utilisateur (traitement système). */
    public static <T> T executerPour(Long organisationId, Supplier<T> action) {
        Contexte precedent = COURANT.get();
        COURANT.set(new Contexte(organisationId, null, null));
        try {
            return action.get();
        } finally {
            if (precedent != null) COURANT.set(precedent);
            else COURANT.remove();
        }
    }
}
