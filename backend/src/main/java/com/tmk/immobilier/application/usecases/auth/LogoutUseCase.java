package com.tmk.immobilier.application.usecases.auth;

import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public class LogoutUseCase {

    private final KeycloakAuthPort keycloakAuthPort;

    public void execute(String refreshToken) {
        keycloakAuthPort.logout(refreshToken);
    }
}
