package com.tmk.immobilier.application.domain.auth;

public record TokenResponse(
        String accessToken,
        String refreshToken,
        long expiresIn,
        long refreshExpiresIn,
        String tokenType
) {
}
