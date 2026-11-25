package com.tmk.immobilier.application.domain.commun;

import com.tmk.immobilier.application.exception.RegleMetierException;

/**
 * Raison métier qui interdit de supprimer une donnée (bail, historique…).
 * Exposée avant tout clic pour que le client grise l'action et dise quoi faire,
 * puis levée telle quelle si la suppression est tentée malgré tout.
 */
public record BlocageSuppression(String code, String message) {

    public RegleMetierException enException() {
        return new RegleMetierException(code, message);
    }
}
