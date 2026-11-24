package com.tmk.immobilier.infrastructure.keycloak;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.keycloak")
public record KeycloakProperties(
        String authServerUrl,
        String realm,
        String clientId,
        String clientSecret
) {
    public String tokenEndpoint() {
        return authServerUrl + "/realms/" + realm + "/protocol/openid-connect/token";
    }

    public String logoutEndpoint() {
        return authServerUrl + "/realms/" + realm + "/protocol/openid-connect/logout";
    }

    /** API d'administration des comptes du realm (compte de service du client backend). */
    public String usersEndpoint() {
        return authServerUrl + "/admin/realms/" + realm + "/users";
    }
}
