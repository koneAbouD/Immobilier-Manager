package com.tmk.immobilier.application.domain.locataire;

import com.tmk.immobilier.application.domain.appartement.TypeLogement;

import java.math.BigDecimal;

/**
 * Locataire vu depuis la liste : qui il est, où il loge et où en sont ses
 * loyers. Calculé à la lecture, jamais persisté.
 *
 * @param logementReference logement du bail actif le plus récent (null sans bail)
 * @param montantEnRetard   somme des restes dus sur les loyers échus
 * @param joursRetard       jours écoulés depuis le plus ancien loyer échu impayé (0 si à jour)
 * @param contratsASigner   baux actifs dont le contrat signé n'a pas été chargé
 */
public record LocataireResume(
        Locataire locataire,
        SituationLocataire situation,
        int nombreBauxActifs,
        String logementReference,
        String immeubleNom,
        TypeLogement typeLogement,
        BigDecimal montantEnRetard,
        int joursRetard,
        int contratsASigner
) {
}
