package com.tmk.immobilier.infrastructure.organisation;

import org.hibernate.context.spi.CurrentTenantIdentifierResolver;

/**
 * Fournit à Hibernate l'organisation de la session qui s'ouvre. Hibernate
 * ajoute alors {@code organisation_id = ?} à toute requête HQL / Criteria sur
 * une entité {@code @TenantId}, et renseigne la colonne à l'insertion.
 *
 * <p>Hors contexte, la valeur {@link ContexteOrganisation#AUCUNE} rend les
 * tables métier vides et toute insertion impossible : on échoue fermé.
 * Aucune organisation n'est « racine » : même l'administration de la
 * plateforme ne lit pas les données métier par ce chemin.
 */
public class OrganisationTenantResolver implements CurrentTenantIdentifierResolver<Long> {

    @Override
    public Long resolveCurrentTenantIdentifier() {
        return ContexteOrganisation.organisationIdOuAucune();
    }

    @Override
    public boolean validateExistingCurrentSessions() {
        return false;
    }

    @Override
    public boolean isRoot(Long tenantId) {
        return false;
    }
}
