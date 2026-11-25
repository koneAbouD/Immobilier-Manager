package com.tmk.immobilier.interfaces.rest.common;

import com.tmk.immobilier.application.domain.commun.BlocageSuppression;

import java.util.Optional;

/**
 * Possibilité de supprimer une donnée au vu de son état (bail, historique…),
 * indépendamment du rôle de l'appelant : le client grise l'action et affiche
 * {@code motif} quand {@code possible} est faux.
 */
public record SuppressionResponse(boolean possible, String code, String motif) {

    public static SuppressionResponse depuis(Optional<BlocageSuppression> blocage) {
        return blocage.map(b -> new SuppressionResponse(false, b.code(), b.message()))
                .orElseGet(() -> new SuppressionResponse(true, null, null));
    }
}
