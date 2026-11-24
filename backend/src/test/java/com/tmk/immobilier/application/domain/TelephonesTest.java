package com.tmk.immobilier.application.domain;

import com.tmk.immobilier.application.common.Telephones;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class TelephonesTest {

    @Test
    void toutesLesSaisiesDUnNumeroIvoirienDonnentLeMemeIdentifiant() {
        assertThat(Telephones.canonique("07 07 12 34 56")).isEqualTo("0707123456");
        assertThat(Telephones.canonique("07.07.12.34.56")).isEqualTo("0707123456");
        assertThat(Telephones.canonique("+225 07 07 12 34 56")).isEqualTo("0707123456");
        assertThat(Telephones.canonique("00225 0707123456")).isEqualTo("0707123456");
    }

    @Test
    void unNumeroEtrangerGardeSonIndicatif() {
        assertThat(Telephones.canonique("+33 6 12 34 56 78")).isEqualTo("+33612345678");
        assertThat(Telephones.canonique("0033612345678")).isEqualTo("+33612345678");
    }

    @Test
    void distingueUnNumeroDUnIdentifiant() {
        assertThat(Telephones.ressembleAUnNumero("07 07 12 34 56")).isTrue();
        assertThat(Telephones.ressembleAUnNumero("+225 0707123456")).isTrue();
        assertThat(Telephones.ressembleAUnNumero("awa@agence.ci")).isFalse();
        assertThat(Telephones.ressembleAUnNumero("gestionnaire.demo")).isFalse();
        assertThat(Telephones.estValide("0707123456")).isTrue();
        assertThat(Telephones.estValide("12ab")).isFalse();
    }
}
