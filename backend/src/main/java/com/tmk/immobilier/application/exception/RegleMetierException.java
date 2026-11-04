package com.tmk.immobilier.application.exception;

/**
 * Refus d'une opération par une règle de gestion (logement déjà loué, paiement
 * supérieur au reste dû…). Renvoyé en 409 : la requête est bien formée, c'est
 * l'état des données qui l'interdit. Le {@code code} permet au client de
 * réagir précisément sans analyser le message.
 */
public class RegleMetierException extends RuntimeException {

    private final String code;

    public RegleMetierException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
