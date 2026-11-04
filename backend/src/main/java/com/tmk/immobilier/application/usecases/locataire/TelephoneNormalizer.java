package com.tmk.immobilier.application.usecases.locataire;

/**
 * Forme canonique d'un numéro : sans espaces, points ni tirets. Sans elle,
 * « 07 07 12 34 56 » et « 0707123456 » passeraient pour deux locataires.
 */
final class TelephoneNormalizer {

    private TelephoneNormalizer() {
    }

    static String normaliser(String telephone) {
        return telephone == null ? null : telephone.replaceAll("[\\s.\\-()]", "");
    }
}
