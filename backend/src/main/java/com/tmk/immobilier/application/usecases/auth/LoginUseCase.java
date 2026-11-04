package com.tmk.immobilier.application.usecases.auth;

import com.tmk.immobilier.application.domain.auth.TokenResponse;
import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public class LoginUseCase {

    private final KeycloakAuthPort keycloakAuthPort;

    public TokenResponse execute(String username, String password) {
        return keycloakAuthPort.login(username.trim(), password);
    }
}
