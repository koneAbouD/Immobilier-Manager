package com.tmk.immobilier.application.exception;

/** L'opération dépasserait une limite de la formule d'abonnement (renvoyée en 402). */
public class LimiteAbonnementException extends RuntimeException {

    private final String code;

    public LimiteAbonnementException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
