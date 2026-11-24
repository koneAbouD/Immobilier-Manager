package com.tmk.immobilier.interfaces.rest.auth.dto;

import com.tmk.immobilier.application.domain.organisation.PlanAbonnement;

/** Formule présentée à l'inscription et dans l'écran Abonnement. Limite nulle = illimité, tarif nul = sur devis. */
public record PlanResponse(String code, String libelle, Integer lotsMax, Integer membresMax, Long tarifMensuel,
                           String devise) {

    public static PlanResponse from(PlanAbonnement plan) {
        return new PlanResponse(plan.name(), plan.getLibelle(), plan.getLotsMax(), plan.getMembresMax(),
                plan.getTarifMensuel(), "XOF");
    }
}
