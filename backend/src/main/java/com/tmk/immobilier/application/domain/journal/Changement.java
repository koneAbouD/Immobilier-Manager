package com.tmk.immobilier.application.domain.journal;

/**
 * Un champ touché par l'opération, en clair (« Loyer mensuel » : « 150 000 FCFA »
 * → « 175 000 FCFA »). Une valeur nulle signifie « non renseigné » ; pour une
 * suppression, {@code apres} est toujours nul.
 */
public record Changement(String champ, String avant, String apres) {
}
