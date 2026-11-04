package com.tmk.immobilier.interfaces.rest.maintenance.dto.request;

import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.time.LocalDate;

public record TerminerMaintenanceRequest(
        @PositiveOrZero(message = "Le coût réel ne peut pas être négatif.") BigDecimal coutReel,
        /** À défaut, aujourd'hui. */
        LocalDate dateRealisation
) {
}
