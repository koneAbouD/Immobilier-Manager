package com.tmk.immobilier.application.domain.tableaubord;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Synthèse du parc et des loyers pour un mois donné.
 *
 * @param loyersAttendus  total dû sur les échéances du mois (hors annulées)
 * @param loyersEncaisses part déjà payée de ces mêmes échéances
 * @param impayes         reste dû de toutes les échéances échues, tous mois confondus
 */
public record TableauBord(
        LocalDate periode,
        long nombreImmeubles,
        long nombreAppartements,
        long nombreAppartementsOccupes,
        long nombreLocatairesActifs,
        BigDecimal loyersAttendus,
        BigDecimal loyersEncaisses,
        BigDecimal impayes,
        long nombreEcheancesEnRetard,
        long maintenancesOuvertes,
        long maintenancesUrgentes
) {
    /** Pourcentage de logements occupés, arrondi à l'unité. */
    public int tauxOccupation() {
        return nombreAppartements == 0 ? 0
                : (int) Math.round(100.0 * nombreAppartementsOccupes / nombreAppartements);
    }

    /** Pourcentage des loyers du mois déjà encaissés, arrondi à l'unité. */
    public int tauxRecouvrement() {
        return loyersAttendus.signum() == 0 ? 0
                : loyersEncaisses.multiply(BigDecimal.valueOf(100))
                        .divide(loyersAttendus, 0, java.math.RoundingMode.HALF_UP).intValue();
    }
}
