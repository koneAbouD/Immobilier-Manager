package com.tmk.immobilier.infrastructure.stockage;

/** Le stockage objet ne répond pas ou refuse l'opération. */
public class StockageIndisponibleException extends RuntimeException {

    public StockageIndisponibleException(String message, Throwable cause) {
        super(message, cause);
    }
}
