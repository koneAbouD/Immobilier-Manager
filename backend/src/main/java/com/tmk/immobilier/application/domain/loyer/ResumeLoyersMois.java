package com.tmk.immobilier.application.domain.loyer;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;

/**
 * Loyers d'un mois, éventuellement limités à un bien : total dû des échéances
 * (hors annulées) et part déjà encaissée.
 */
public record ResumeLoyersMois(LocalDate periode, Long immeubleId, BigDecimal attendu, BigDecimal encaisse) {

    /** Reste à encaisser sur le mois, jamais négatif. */
    public BigDecimal reste() {
        return attendu.subtract(encaisse).max(BigDecimal.ZERO);
    }

    /** Pourcentage encaissé, arrondi à l'unité. */
    public int tauxRecouvrement() {
        return attendu.signum() == 0 ? 0
                : encaisse.multiply(BigDecimal.valueOf(100)).divide(attendu, 0, RoundingMode.HALF_UP).intValue();
    }
}
