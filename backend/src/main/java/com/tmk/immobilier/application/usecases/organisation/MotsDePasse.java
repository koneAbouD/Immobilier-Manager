package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.exception.RegleMetierException;

import java.security.SecureRandom;

/** Politique de mot de passe des comptes créés par la plateforme. */
public final class MotsDePasse {

    public static final int LONGUEUR_MIN = 8;

    private static final SecureRandom ALEA = new SecureRandom();
    // Sans caractères ambigus (0/O, 1/l/I) : le mot de passe est dicté ou recopié.
    private static final String MINUSCULES = "abcdefghijkmnopqrstuvwxyz";
    private static final String MAJUSCULES = "ABCDEFGHJKLMNPQRSTUVWXYZ";
    private static final String CHIFFRES = "23456789";

    private MotsDePasse() {
    }

    public static void verifierRobustesse(String motDePasse) {
        if (motDePasse == null || motDePasse.length() < LONGUEUR_MIN
                || motDePasse.chars().noneMatch(Character::isLetter)
                || motDePasse.chars().noneMatch(Character::isDigit)) {
            throw new RegleMetierException("MOT_DE_PASSE_FAIBLE",
                    "Le mot de passe doit compter au moins " + LONGUEUR_MIN + " caractères, dont une lettre et un chiffre.");
        }
    }

    /** Mot de passe provisoire de 12 caractères, lisible à voix haute. */
    public static String generer() {
        StringBuilder sb = new StringBuilder();
        String tous = MINUSCULES + MAJUSCULES + CHIFFRES;
        sb.append(MAJUSCULES.charAt(ALEA.nextInt(MAJUSCULES.length())));
        sb.append(CHIFFRES.charAt(ALEA.nextInt(CHIFFRES.length())));
        for (int i = 0; i < 10; i++) sb.append(tous.charAt(ALEA.nextInt(tous.length())));
        return sb.toString();
    }
}
