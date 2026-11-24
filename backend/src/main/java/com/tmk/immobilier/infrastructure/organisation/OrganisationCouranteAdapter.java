package com.tmk.immobilier.infrastructure.organisation;

import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class OrganisationCouranteAdapter implements OrganisationCourantePort {

    @Override
    public Long id() {
        return ContexteOrganisation.courant()
                .map(ContexteOrganisation.Contexte::organisationId)
                .orElseThrow(() -> new IllegalStateException("Aucune organisation dans le contexte courant"));
    }

    @Override
    public Optional<Long> utilisateurId() {
        return ContexteOrganisation.courant().map(ContexteOrganisation.Contexte::utilisateurId);
    }

    @Override
    public Optional<RoleMembre> role() {
        return ContexteOrganisation.courant().map(ContexteOrganisation.Contexte::role);
    }
}
