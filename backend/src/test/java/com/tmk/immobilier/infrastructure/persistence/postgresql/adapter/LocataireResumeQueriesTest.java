package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class LocataireResumeQueriesTest {

    private static List<String> toutesLesRequetes(boolean bien) {
        List<String> requetes = new ArrayList<>();
        for (boolean recherche : new boolean[]{false, true}) {
            requetes.add(LocataireResumeQueries.comptes(recherche, bien));
            for (boolean situation : new boolean[]{false, true}) {
                requetes.add(LocataireResumeQueries.page(recherche, bien, situation));
                requetes.add(LocataireResumeQueries.total(recherche, bien, situation));
            }
        }
        return requetes;
    }

    @Test
    void aucunMarqueurNeResteDansLeSql() {
        for (boolean bien : new boolean[]{false, true}) {
            toutesLesRequetes(bien).forEach(sql -> assertThat(sql).doesNotContain("{").doesNotContain("%s"));
        }
    }

    @Test
    void leFiltreParBienNApparaitQueSIlEstDemande() {
        toutesLesRequetes(false).forEach(sql -> assertThat(sql).doesNotContain(":immeuble"));
        toutesLesRequetes(true).forEach(sql -> assertThat(sql).contains(":immeuble"));
        // Le logement affiché se limite au bien choisi.
        assertThat(LocataireResumeQueries.page(false, true, false))
                .contains("b.statut = 'ACTIF' AND EXISTS (SELECT 1 FROM appartements ab");
    }
}
