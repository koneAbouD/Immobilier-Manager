package com.tmk.immobilier.application.usecases.plateforme;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.PlanAbonnement;
import com.tmk.immobilier.application.domain.organisation.StatutAbonnement;
import com.tmk.immobilier.application.domain.organisation.UsageAbonnement;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Map;

/**
 * Back-office de l'éditeur (rôle Keycloak SUPER_ADMIN) : suivi des
 * organisations clientes et de leurs abonnements. Ne donne jamais accès aux
 * données métier des organisations.
 */
@RequiredArgsConstructor
public class AdministrationPlateformeUseCase {

    public record OrganisationSuivie(Organisation organisation, UsageAbonnement usage) {
    }

    private final OrganisationRepository organisationRepository;

    @Transactional(readOnly = true)
    public PageResult<OrganisationSuivie> lister(String recherche, int page, int size) {
        PageResult<Organisation> organisations = organisationRepository.findPage(recherche, page, size);
        Map<Long, UsageAbonnement> usages = organisationRepository.usages(
                organisations.content().stream().map(Organisation::getId).toList());
        return organisations.map(o -> new OrganisationSuivie(o,
                usages.getOrDefault(o.getId(), new UsageAbonnement(0, 0, 0))));
    }

    /**
     * Change la formule et l'état de l'abonnement (activation après paiement,
     * prolongation d'essai, suspension…). Une formule ne peut pas descendre
     * sous la consommation actuelle : il faudrait d'abord retirer des lots.
     */
    @Transactional
    public OrganisationSuivie modifierAbonnement(Long organisationId, PlanAbonnement plan, StatutAbonnement statut,
                                                 LocalDate essaiFinLe, LocalDate abonnementFinLe) {
        Organisation organisation = organisationRepository.findById(organisationId)
                .orElseThrow(() -> ResourceNotFoundException.of("Organisation", organisationId));
        UsageAbonnement usage = organisationRepository.usage(organisationId);
        if (plan != null) {
            if (!plan.autoriseLots(usage.lots()) || !plan.autoriseMembres(usage.membres())) {
                throw new RegleMetierException("FORMULE_INSUFFISANTE",
                        "La formule " + plan.getLibelle() + " ne couvre pas la consommation actuelle ("
                                + usage.lots() + " lots, " + usage.membres() + " utilisateurs).");
            }
            organisation.setPlan(plan);
        }
        if (statut != null) organisation.setStatutAbonnement(statut);
        if (essaiFinLe != null) organisation.setEssaiFinLe(essaiFinLe);
        organisation.setAbonnementFinLe(abonnementFinLe);
        return new OrganisationSuivie(organisationRepository.save(organisation), usage);
    }
}
