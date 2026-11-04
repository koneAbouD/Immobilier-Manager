package com.tmk.immobilier.infrastructure.keycloak;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.tmk.immobilier.application.domain.auth.TokenResponse;
import com.tmk.immobilier.application.exception.AuthServiceUnavailableException;
import com.tmk.immobilier.application.exception.AuthenticationFailedException;
import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.time.Duration;

/**
 * Dialogue avec le endpoint OpenID Connect de Keycloak. Le mobile ne connaît
 * que le backend : le secret du client confidentiel ne quitte jamais le serveur.
 */
@Slf4j
@Component
@EnableConfigurationProperties(KeycloakProperties.class)
public class KeycloakAuthAdapter implements KeycloakAuthPort {

    private final KeycloakProperties properties;
    private final RestClient restClient;

    public KeycloakAuthAdapter(KeycloakProperties properties, RestClient.Builder builder) {
        this.properties = properties;
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(Duration.ofSeconds(5));
        requestFactory.setReadTimeout(Duration.ofSeconds(10));
        this.restClient = builder.requestFactory(requestFactory).build();
    }

    @Override
    public TokenResponse login(String username, String password) {
        MultiValueMap<String, String> form = formulaireClient("password");
        form.add("username", username);
        form.add("password", password);
        form.add("scope", "openid");
        return demanderJeton(form, "Identifiant ou mot de passe incorrect.");
    }

    @Override
    public TokenResponse refreshToken(String refreshToken) {
        MultiValueMap<String, String> form = formulaireClient("refresh_token");
        form.add("refresh_token", refreshToken);
        return demanderJeton(form, "Session expirée, veuillez vous reconnecter.");
    }

    @Override
    public void logout(String refreshToken) {
        MultiValueMap<String, String> form = formulaireClient(null);
        form.add("refresh_token", refreshToken);
        try {
            restClient.post().uri(properties.logoutEndpoint())
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .toBodilessEntity();
        } catch (RestClientException e) {
            // La déconnexion côté client a eu lieu : une session Keycloak déjà
            // expirée ou injoignable ne doit pas faire échouer l'opération.
            log.warn("Déconnexion Keycloak non confirmée : {}", e.getMessage());
        }
    }

    private MultiValueMap<String, String> formulaireClient(String grantType) {
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        if (grantType != null) form.add("grant_type", grantType);
        form.add("client_id", properties.clientId());
        form.add("client_secret", properties.clientSecret());
        return form;
    }

    private TokenResponse demanderJeton(MultiValueMap<String, String> form, String messageRefus) {
        try {
            KeycloakToken token = restClient.post().uri(properties.tokenEndpoint())
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .body(KeycloakToken.class);
            if (token == null) {
                throw new AuthServiceUnavailableException("Réponse vide du service d'authentification.", null);
            }
            return new TokenResponse(token.accessToken(), token.refreshToken(), token.expiresIn(),
                    token.refreshExpiresIn(), token.tokenType());
        } catch (HttpClientErrorException e) {
            // 400/401 : identifiants refusés ou refresh token invalide.
            log.debug("Keycloak a refusé la demande de jeton : {} {}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new AuthenticationFailedException(messageRefus);
        } catch (ResourceAccessException e) {
            throw new AuthServiceUnavailableException("Service d'authentification injoignable.", e);
        } catch (RestClientException e) {
            throw new AuthServiceUnavailableException("Service d'authentification indisponible.", e);
        }
    }

    private record KeycloakToken(
            @JsonProperty("access_token") String accessToken,
            @JsonProperty("refresh_token") String refreshToken,
            @JsonProperty("expires_in") long expiresIn,
            @JsonProperty("refresh_expires_in") long refreshExpiresIn,
            @JsonProperty("token_type") String tokenType
    ) {
    }
}
