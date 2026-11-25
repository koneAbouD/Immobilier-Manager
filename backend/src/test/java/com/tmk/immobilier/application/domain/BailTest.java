package com.tmk.immobilier.application.domain;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.appartement.TypeLogement;
import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.domain.bail.UsageBail;
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

    @Test
    void leDepotDeGarantieVautLesMoisDeCautionFoisLeLoyer() {
        Bail bail = bail(LocalDate.of(2026, 1, 15));
        bail.setMoisCaution(3);

        bail.appliquerCaution();

        assertThat(bail.getDepotGarantie()).isEqualByComparingTo("300000");
    }

    @Test
    void sansMoisDeCautionLeMontantSaisiEstConserve() {
        Bail bail = bail(LocalDate.of(2026, 1, 15));
        bail.setDepotGarantie(new BigDecimal("150000"));

        bail.appliquerCaution();

        assertThat(bail.getDepotGarantie()).isEqualByComparingTo("150000");
    }

    @Test
    void unNombreDeMoisDeCautionHorsBornesEstRefuse() {
        Bail bail = bail(LocalDate.of(2026, 1, 15));
        bail.setMoisCaution(25);

        assertThatThrownBy(bail::valider).isInstanceOf(RegleMetierException.class);
    }

    @Test
    void lePremierMoisFactureSuitLaCreationSansAvance() {
        assertThat(Bail.calculerPremierMoisFacture(LocalDate.of(2026, 11, 15), 0, LocalDate.of(2026, 11, 24)))
                .isEqualTo(YearMonth.of(2026, 12));
    }

    @Test
    void lesMoisDAvanceRepoussentLePremierMoisFacture() {
        assertThat(Bail.calculerPremierMoisFacture(LocalDate.of(2026, 12, 1), 2, LocalDate.of(2026, 11, 24)))
                .isEqualTo(YearMonth.of(2027, 2));
        assertThat(Bail.calculerPremierMoisFacture(LocalDate.of(2027, 3, 1), 1, LocalDate.of(2026, 11, 24)))
                .isEqualTo(YearMonth.of(2027, 4));
    }

    @Test
    void unBailAncienNEstPasFactureRetroactivement() {
        assertThat(Bail.calculerPremierMoisFacture(LocalDate.of(2024, 1, 1), 2, LocalDate.of(2026, 11, 24)))
                .isEqualTo(YearMonth.of(2026, 12));
    }

    @Test
    void aucunLoyerNEstDuAvantLePremierMoisFacture() {
        Bail bail = Bail.builder().dateDebut(LocalDate.of(2026, 12, 1)).moisAvance(2)
                .loyerMensuel(new BigDecimal("100000")).charges(new BigDecimal("5000")).build();
        bail.setCreeLe(LocalDate.of(2026, 11, 24));
        bail.recalculerPremierMoisFacture();

        assertThat(bail.getPremierMoisFacture()).isEqualTo(LocalDate.of(2027, 2, 1));
        assertThat(bail.couvre(YearMonth.of(2027, 1))).isFalse();
        assertThat(bail.couvre(YearMonth.of(2027, 2))).isTrue();
        assertThat(bail.montantAvance()).isEqualByComparingTo("210000");
    }

    @Test
    void lePremierMoisFactureNePeutPrecederLeDebut() {
        Bail bail = Bail.builder().dateDebut(LocalDate.of(2026, 12, 10))
                .loyerMensuel(new BigDecimal("100000")).build();
        bail.definirPremierMoisFacture(LocalDate.of(2026, 11, 20));
        assertThatThrownBy(bail::valider).hasMessageContaining("premier loyer");
    }

    @Test
    void leRegimeParDefautSuitLaNatureDuLocal() {
        Bail habitation = Bail.builder().appartement(Appartement.builder().type(TypeLogement.APPARTEMENT).build()).build();
        habitation.initializeDefaults();
        assertThat(habitation.getUsage()).isEqualTo(UsageBail.HABITATION);

        Bail magasin = Bail.builder().appartement(Appartement.builder().type(TypeLogement.MAGASIN).build()).build();
        magasin.initializeDefaults();
        assertThat(magasin.getUsage()).isEqualTo(UsageBail.PROFESSIONNEL);
    }

    @Test
    void unRegimeChoisiLEmporteSurLaNatureDuLocal() {
        Bail bail = Bail.builder().usage(UsageBail.PROFESSIONNEL)
                .appartement(Appartement.builder().type(TypeLogement.APPARTEMENT).build()).build();
        bail.initializeDefaults();
        assertThat(bail.getUsage()).isEqualTo(UsageBail.PROFESSIONNEL);
        assertThat(bail.estProfessionnel()).isTrue();
    }
}
