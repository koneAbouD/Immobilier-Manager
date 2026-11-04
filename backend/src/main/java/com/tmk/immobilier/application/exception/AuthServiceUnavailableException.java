package com.tmk.immobilier.application.exception;

public class AuthServiceUnavailableException extends RuntimeException {

    public AuthServiceUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }
}
