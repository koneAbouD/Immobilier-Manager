package com.tmk.immobilier.interfaces.rest.tableaubord.dto;

import com.tmk.immobilier.application.domain.tableaubord.TableauBord;

import java.math.BigDecimal;
import java.time.LocalDate;

public record TableauBordResponse(
        LocalDate periode,
        long nombreImmeubles,
        long nombreAppartements,
        long nombreAppartementsOccupes,
        int tauxOccupation,
        long nombreLocatairesActifs,
        BigDecimal loyersAttendus,
        BigDecimal loyersEncaisses,
        int tauxRecouvrement,
        BigDecimal impayes,
        long nombreEcheancesEnRetard,
        long maintenancesOuvertes,
        long maintenancesUrgentes
) {
    public static TableauBordResponse from(TableauBord t) {
        return new TableauBordResponse(t.periode(), t.nombreImmeubles(), t.nombreAppartements(),
                t.nombreAppartementsOccupes(), t.tauxOccupation(), t.nombreLocatairesActifs(),
                t.loyersAttendus(), t.loyersEncaisses(), t.tauxRecouvrement(), t.impayes(),
                t.nombreEcheancesEnRetard(), t.maintenancesOuvertes(), t.maintenancesUrgentes());
    }
}
