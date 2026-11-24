package com.tmk.immobilier.infrastructure.keycloak;

import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.JdkClientHttpRequestFactory;

import java.net.http.HttpClient;
import java.time.Duration;

/**
 * Client HTTP vers Keycloak. Client du JDK ({@link HttpClient}) et non
 * {@code HttpURLConnection} : ce dernier perd le corps des réponses 401, si
 * bien qu'un mot de passe erroné ({@code invalid_grant}) passait pour une panne
 * du service d'authentification.
 */
final class KeycloakHttp {

    private KeycloakHttp() {
    }

    static ClientHttpRequestFactory requestFactory() {
        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(client);
        factory.setReadTimeout(Duration.ofSeconds(10));
        return factory;
    }
}
