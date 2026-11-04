package com.tmk.immobilier.application.domain;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.exception.RegleMetierException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class BailTest {

    private Bail bail(LocalDate debut) {
        Bail bail = Bail.builder()
                .dateDebut(debut)
                .loyerMensuel(new BigDecimal("100000"))
                .charges(new BigDecimal("10000"))
                .build();
        bail.initializeDefaults();
        return bail;
    }

    @Test
    void leMontantMensuelCumuleLoyerEtCharges() {
        assertThat(bail(LocalDate.of(2026, 1, 15)).montantMensuel()).isEqualByComparingTo("110000");
    }

    @Test
    void leMoisDeDebutEstCouvertMemeEnCoursDeMois() {
        Bail bail = bail(LocalDate.of(2026, 1, 15));

        assertThat(bail.couvre(YearMonth.of(2025, 12))).isFalse();
        assertThat(bail.couvre(YearMonth.of(2026, 1))).isTrue();
    }

    @Test
    void apresResiliationLeMoisDeResiliationResteDuMaisPasLesSuivants() {
        Bail bail = bail(LocalDate.of(2026, 1, 15));

        bail.resilier(LocalDate.of(2026, 4, 10), "Départ", "gestionnaire");

        assertThat(bail.getStatut()).isEqualTo(StatutBail.RESILIE);
        assertThat(bail.couvre(YearMonth.of(2026, 4))).isTrue();
        assertThat(bail.couvre(YearMonth.of(2026, 5))).isFalse();
    }

    @Test
    void uneResiliationAnterieureAuDebutEstRefusee() {
        Bail bail = bail(LocalDate.of(2026, 1, 15));

        assertThatThrownBy(() -> bail.resilier(LocalDate.of(2026, 1, 1), "x", "y"))
                .isInstanceOf(RegleMetierException.class);
    }

    @Test
    void laDateEcheanceSuitLeJourDuBail() {
        Bail bail = bail(LocalDate.of(2026, 1, 15));
        bail.setJourEcheance(10);

        assertThat(bail.dateEcheancePour(YearMonth.of(2026, 2))).isEqualTo(LocalDate.of(2026, 2, 10));
    }
}
