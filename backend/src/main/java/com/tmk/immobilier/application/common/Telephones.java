package com.tmk.immobilier.application.common;

import java.util.regex.Pattern;

/**
 * Numéro de téléphone servant d'identifiant de connexion. Une seule forme
 * canonique, pour que « 07 07 12 34 56 », « 0707123456 » et
 * « +225 07 07 12 34 56 » ouvrent le même compte.
 */
public final class Telephones {

    /** Indicatif local : un numéro ivoirien s'enregistre sous ses 10 chiffres nationaux. */
    private static final String INDICATIF_LOCAL = "+225";

    private static final Pattern FORME_TELEPHONE = Pattern.compile("^\\+?[0-9 .\\-()]{8,20}$");
    private static final Pattern CANONIQUE = Pattern.compile("^\\+?[0-9]{8,15}$");

    private Telephones() {
    }

    /** Vrai si la saisie ressemble à un numéro (et pas à une adresse e-mail ou un identifiant). */
    public static boolean ressembleAUnNumero(String saisie) {
        return saisie != null && FORME_TELEPHONE.matcher(saisie.trim()).matches();
    }

    /**
     * Forme canonique : sans séparateurs, « 00 » devenu « + », indicatif
     * ivoirien retiré devant un numéro national à 10 chiffres.
     */
    public static String canonique(String saisie) {
        if (saisie == null) return null;
        String n = saisie.replaceAll("[\\s.\\-()]", "");
        if (n.startsWith("00")) n = "+" + n.substring(2);
        if (n.startsWith(INDICATIF_LOCAL) && n.length() == INDICATIF_LOCAL.length() + 10) {
            n = n.substring(INDICATIF_LOCAL.length());
        }
        return n;
    }

    public static boolean estValide(String canonique) {
        return canonique != null && CANONIQUE.matcher(canonique).matches();
    }
}
