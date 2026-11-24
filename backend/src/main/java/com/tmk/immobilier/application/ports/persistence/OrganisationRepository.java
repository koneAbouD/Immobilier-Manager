package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.UsageAbonnement;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/** Organisations clientes : table globale, hors cloisonnement par organisation. */
public interface OrganisationRepository {

    Organisation save(Organisation organisation);

    Optional<Organisation> findById(Long id);

    Optional<Organisation> findHistorique();

    /** Toutes les organisations dont les membres peuvent encore écrire (émission des loyers). */
    List<Long> findIdsActives();

    /** @param recherche nom, e-mail ou téléphone ; ignoré s'il est vide */
    PageResult<Organisation> findPage(String recherche, int page, int size);

    /** Consommation (biens, lots, membres actifs) de chacune des organisations données. */
    Map<Long, UsageAbonnement> usages(Collection<Long> organisationIds);

    default UsageAbonnement usage(Long organisationId) {
        return usages(List.of(organisationId)).getOrDefault(organisationId, new UsageAbonnement(0, 0, 0));
    }
}
