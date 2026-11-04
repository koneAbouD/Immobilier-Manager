package com.tmk.immobilier.interfaces.rest.auth.dto;

import com.tmk.immobilier.application.domain.auth.TokenResponse;

public record TokenResponseDto(
        String accessToken,
        String refreshToken,
        long expiresIn,
        long refreshExpiresIn,
        String tokenType
) {
    public static TokenResponseDto from(TokenResponse token) {
        return new TokenResponseDto(token.accessToken(), token.refreshToken(), token.expiresIn(),
                token.refreshExpiresIn(), token.tokenType());
    }
}
