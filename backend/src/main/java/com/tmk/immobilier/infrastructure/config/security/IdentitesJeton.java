package com.tmk.immobilier.infrastructure.config.security;

import com.tmk.immobilier.application.usecases.organisation.IdentiteJeton;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

import java.util.HashSet;

/** Extraction de l'identité de l'appelant depuis son jeton. */
public final class IdentitesJeton {

    private IdentitesJeton() {
    }

    public static IdentiteJeton depuis(Authentication authentication) {
        if (!(authentication instanceof JwtAuthenticationToken jwtAuth)) {
            throw new IllegalStateException("Authentification par jeton attendue");
        }
        Jwt jwt = jwtAuth.getToken();
        return new IdentiteJeton(
                jwt.getSubject(),
                jwt.getClaimAsString("email"),
                jwt.getClaimAsString("given_name"),
                jwt.getClaimAsString("family_name"),
                new HashSet<>(JwtAuthConverter.rolesRealm(jwt)));
    }
}
