package com.tmk.immobilier.application.domain;

import com.tmk.immobilier.application.domain.organisation.AccesOrganisation;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.PlanAbonnement;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.domain.organisation.StatutAbonnement;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class OrganisationTest {

    private static final LocalDate AUJOURDHUI = LocalDate.of(2026, 11, 23);

    @Test
    void uneInscriptionOuvreUnEssaiCompletDeTrenteJours() {
        Organisation o = Organisation.nouvelleEnEssai("  Agence Horizon ", AUJOURDHUI);

        assertThat(o.getNom()).isEqualTo("Agence Horizon");
        assertThat(o.getStatutAbonnement()).isEqualTo(StatutAbonnement.ESSAI);
        assertThat(o.getPlan()).isEqualTo(PlanAbonnement.PLAN_ESSAI);
        assertThat(o.getEssaiFinLe()).isEqualTo(AUJOURDHUI.plusDays(30));
        assertThat(o.acces(AUJOURDHUI)).isEqualTo(AccesOrganisation.COMPLET);
        assertThat(o.joursRestants(AUJOURDHUI)).isEqualTo(30);
    }

    @Test
    void unEssaiEchuPasseEnLectureSeule() {
        Organisation o = Organisation.nouvelleEnEssai("Agence", AUJOURDHUI.minusDays(31));

        assertThat(o.acces(AUJOURDHUI)).isEqualTo(AccesOrganisation.LECTURE_SEULE);
        assertThat(o.motifRestriction(AUJOURDHUI)).contains("essai");
    }

    @Test
    void lAccesSuitLEtatDeLAbonnement() {
        Organisation o = Organisation.builder().nom("A").plan(PlanAbonnement.ESSENTIEL)
                .statutAbonnement(StatutAbonnement.ACTIF).build();
        assertThat(o.acces(AUJOURDHUI)).as("sans échéance").isEqualTo(AccesOrganisation.COMPLET);

        o.setAbonnementFinLe(AUJOURDHUI.minusDays(1));
        assertThat(o.acces(AUJOURDHUI)).as("échu").isEqualTo(AccesOrganisation.LECTURE_SEULE);

        o.setStatutAbonnement(StatutAbonnement.SUSPENDU);
        assertThat(o.acces(AUJOURDHUI)).isEqualTo(AccesOrganisation.LECTURE_SEULE);

        o.setStatutAbonnement(StatutAbonnement.RESILIE);
        assertThat(o.acces(AUJOURDHUI)).isEqualTo(AccesOrganisation.BLOQUE);
    }

    @Test
    void lesLimitesDesFormules() {
        assertThat(PlanAbonnement.GRATUIT.autoriseLots(5)).isTrue();
        assertThat(PlanAbonnement.GRATUIT.autoriseLots(6)).isFalse();
        assertThat(PlanAbonnement.ENTREPRISE.autoriseLots(1_000_000)).isTrue();
        assertThat(PlanAbonnement.ENTREPRISE.autoriseMembres(500)).isTrue();
    }

    @Test
    void lesRolesSEmboitent() {
        assertThat(RoleMembre.PROPRIETAIRE.inclut(RoleMembre.LECTEUR)).isTrue();
        assertThat(RoleMembre.ADMIN.inclut(RoleMembre.GESTIONNAIRE)).isTrue();
        assertThat(RoleMembre.GESTIONNAIRE.inclut(RoleMembre.ADMIN)).isFalse();
        assertThat(RoleMembre.LECTEUR.inclut(RoleMembre.GESTIONNAIRE)).isFalse();
    }
}
