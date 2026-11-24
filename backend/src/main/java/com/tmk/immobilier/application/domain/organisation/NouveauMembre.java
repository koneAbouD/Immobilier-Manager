package com.tmk.immobilier.application.domain.organisation;

/**
 * Résultat d'un ajout de membre. [motDePasseTemporaire] n'est renseigné que si
 * le compte a été créé : il est montré une seule fois à l'administrateur, qui
 * le transmet à l'intéressé.
 */
public record NouveauMembre(Membre membre, String motDePasseTemporaire) {
}
