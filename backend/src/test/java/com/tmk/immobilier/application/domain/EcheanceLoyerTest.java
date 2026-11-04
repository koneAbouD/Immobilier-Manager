package com.tmk.immobilier.application.domain;

import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.StatutEcheance;
import com.tmk.immobilier.application.exception.RegleMetierException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class EcheanceLoyerTest {

    private EcheanceLoyer echeance(String du) {
        return EcheanceLoyer.builder()
                .periode(LocalDate.of(2026, 10, 1))
                .dateEcheance(LocalDate.of(2026, 10, 5))
                .montantDu(new BigDecimal(du))
                .montantPaye(BigDecimal.ZERO)
                .statut(StatutEcheance.A_PAYER)
                .build();
    }

    @Test
    void unPaiementPartielPuisLeSoldePassentPartielPuisPayee() {
        EcheanceLoyer e = echeance("150000");

        e.enregistrerPaiement(new BigDecimal("50000"));
        assertThat(e.getStatut()).isEqualTo(StatutEcheance.PARTIEL);
        assertThat(e.resteDu()).isEqualByComparingTo("100000");

        e.enregistrerPaiement(new BigDecimal("100000"));
        assertThat(e.getStatut()).isEqualTo(StatutEcheance.PAYEE);
        assertThat(e.resteDu()).isEqualByComparingTo("0");
    }

    @Test
    void unPaiementSuperieurAuResteDuEstRefuse() {
        EcheanceLoyer e = echeance("150000");
        e.enregistrerPaiement(new BigDecimal("100000"));

        assertThatThrownBy(() -> e.enregistrerPaiement(new BigDecimal("50001")))
                .isInstanceOf(RegleMetierException.class)
                .hasMessageContaining("dépasse le reste dû");
        assertThat(e.getMontantPaye()).isEqualByComparingTo("100000");
    }

    @Test
    void retirerUnPaiementRendLEcheanceDue() {
        EcheanceLoyer e = echeance("150000");
        e.enregistrerPaiement(new BigDecimal("150000"));

        e.retirerPaiement(new BigDecimal("150000"));

        assertThat(e.getStatut()).isEqualTo(StatutEcheance.A_PAYER);
        assertThat(e.resteDu()).isEqualByComparingTo("150000");
    }

    @Test
    void uneEcheanceDejaRegleeNePeutPasEtreAnnulee() {
        EcheanceLoyer e = echeance("150000");
        e.enregistrerPaiement(new BigDecimal("1000"));

        assertThatThrownBy(e::annuler).isInstanceOf(RegleMetierException.class);
    }

    @Test
    void enRetardSeulementApresLaDateEcheanceEtSiNonSoldee() {
        EcheanceLoyer e = echeance("150000");

        assertThat(e.estEnRetard(LocalDate.of(2026, 10, 5))).isFalse();
        assertThat(e.estEnRetard(LocalDate.of(2026, 10, 6))).isTrue();

        e.enregistrerPaiement(new BigDecimal("150000"));
        assertThat(e.estEnRetard(LocalDate.of(2026, 10, 6))).isFalse();
    }
}
