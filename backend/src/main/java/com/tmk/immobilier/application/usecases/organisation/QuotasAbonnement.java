package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.PlanAbonnement;
import com.tmk.immobilier.application.domain.organisation.UsageAbonnement;
import com.tmk.immobilier.application.exception.LimiteAbonnementException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import lombok.RequiredArgsConstructor;

/**
 * Fait respecter les limites de la formule de l'organisation courante. Appelé
 * par les use cases qui créent des lots ou des membres, avant toute écriture.
 */
@RequiredArgsConstructor
public class QuotasAbonnement {

    private final OrganisationCourantePort organisationCourante;
    private final OrganisationRepository organisationRepository;

    public void verifierAjoutLots(int nombre) {
        Organisation organisation = courante();
        PlanAbonnement plan = organisation.getPlan();
        UsageAbonnement usage = organisationRepository.usage(organisation.getId());
        if (!plan.autoriseLots(usage.lots() + nombre)) {
            throw new LimiteAbonnementException("LIMITE_LOTS_ATTEINTE",
                    "La formule " + plan.getLibelle() + " est limitée à " + plan.getLotsMax()
                            + " lots. Passez à une formule supérieure pour en ajouter.");
        }
    }

    public void verifierAjoutMembre() {
        Organisation organisation = courante();
        PlanAbonnement plan = organisation.getPlan();
        UsageAbonnement usage = organisationRepository.usage(organisation.getId());
        if (!plan.autoriseMembres(usage.membres() + 1)) {
            throw new LimiteAbonnementException("LIMITE_MEMBRES_ATTEINTE",
                    "La formule " + plan.getLibelle() + " est limitée à " + plan.getMembresMax()
                            + " utilisateur(s). Passez à une formule supérieure pour inviter un collaborateur.");
        }
    }

    private Organisation courante() {
        Long id = organisationCourante.id();
        return organisationRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Organisation", id));
    }
}
