package com.tmk.immobilier.application.usecases.auth;

import com.tmk.immobilier.application.domain.auth.TokenResponse;
import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public class RefreshTokenUseCase {

    private final KeycloakAuthPort keycloakAuthPort;

    public TokenResponse execute(String refreshToken) {
        return keycloakAuthPort.refreshToken(refreshToken);
    }
}
