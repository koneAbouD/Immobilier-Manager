package com.tmk.immobilier.application.domain.bail;

import com.tmk.immobilier.application.domain.appartement.TypeLogement;

/**
 * Régime du bail, choisi à la signature : il fixe le modèle de contrat (titre,
 * destination du local, obligations et préavis propres à chaque régime).
 */
public enum UsageBail {
    /** Logement du preneur et de sa famille ; aucune activité professionnelle. */
    HABITATION,
    /** Exercice d'une activité commerciale, artisanale ou libérale (bureaux, magasin, entrepôt…). */
    PROFESSIONNEL;

    /** Proposé à défaut : habitation pour un appartement, professionnel pour les autres locaux. */
    public static UsageBail parDefautPour(TypeLogement type) {
        return type == null || type == TypeLogement.APPARTEMENT ? HABITATION : PROFESSIONNEL;
    }
}
