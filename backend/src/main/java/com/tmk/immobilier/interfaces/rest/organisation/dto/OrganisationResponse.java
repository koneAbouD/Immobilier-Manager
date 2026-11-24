package com.tmk.immobilier.interfaces.rest.organisation.dto;

import com.tmk.immobilier.application.domain.organisation.AccesOrganisation;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.domain.organisation.UsageAbonnement;
import com.tmk.immobilier.interfaces.rest.auth.dto.PlanResponse;

import java.time.LocalDate;

public record OrganisationResponse(
        Long id,
        String nom,
        String representant,
        String email,
        String telephone,
        String adresse,
        String ville,
        String pays,
        String devise,
        boolean logo,
        AbonnementResponse abonnement,
        String monRole
) {

    public record AbonnementResponse(
            PlanResponse plan,
            String statut,
            String acces,
            String motifRestriction,
            LocalDate essaiFinLe,
            LocalDate abonnementFinLe,
            Long joursRestants,
            long biens,
            long lots,
            long membres
    ) {
    }

    public static OrganisationResponse from(Organisation o, UsageAbonnement usage, RoleMembre monRole) {
        LocalDate aujourdhui = LocalDate.now();
        AccesOrganisation acces = o.acces(aujourdhui);
        return new OrganisationResponse(o.getId(), o.getNom(), o.getRepresentant(), o.getEmail(), o.getTelephone(),
                o.getAdresse(), o.getVille(), o.getPays(), o.getDevise(), o.getLogoCle() != null,
                new AbonnementResponse(PlanResponse.from(o.getPlan()), o.getStatutAbonnement().name(), acces.name(),
                        acces == AccesOrganisation.COMPLET ? null : o.motifRestriction(aujourdhui),
                        o.getEssaiFinLe(), o.getAbonnementFinLe(), o.joursRestants(aujourdhui),
                        usage.biens(), usage.lots(), usage.membres()),
                monRole != null ? monRole.name() : null);
    }
}
