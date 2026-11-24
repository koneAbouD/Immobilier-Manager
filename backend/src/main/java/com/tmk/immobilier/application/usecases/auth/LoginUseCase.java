package com.tmk.immobilier.application.usecases.auth;

import com.tmk.immobilier.application.domain.auth.TokenResponse;
import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import com.tmk.immobilier.application.common.Telephones;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public class LoginUseCase {

    private final KeycloakAuthPort keycloakAuthPort;

    public TokenResponse execute(String username, String password) {
        // Un numéro se saisit de bien des façons : on le ramène à la forme
        // sous laquelle le compte a été créé.
        String identifiant = Telephones.ressembleAUnNumero(username)
                ? Telephones.canonique(username) : username.trim();
        return keycloakAuthPort.login(identifiant, password);
    }
}
