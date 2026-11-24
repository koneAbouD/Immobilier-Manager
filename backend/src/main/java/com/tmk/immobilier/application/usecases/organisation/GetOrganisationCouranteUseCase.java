package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.domain.organisation.UsageAbonnement;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

/** Fiche de l'organisation courante, abonnement et consommation compris. */
@RequiredArgsConstructor
public class GetOrganisationCouranteUseCase {

    public record OrganisationCourante(Organisation organisation, UsageAbonnement usage, RoleMembre monRole) {
    }

    private final OrganisationCourantePort organisationCourante;
    private final OrganisationRepository organisationRepository;

    @Transactional(readOnly = true)
    public OrganisationCourante execute() {
        Long id = organisationCourante.id();
        Organisation organisation = organisationRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Organisation", id));
        return new OrganisationCourante(organisation, organisationRepository.usage(id),
                organisationCourante.role().orElse(null));
    }
}
