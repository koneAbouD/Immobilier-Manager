package com.tmk.immobilier.infrastructure.keycloak;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.tmk.immobilier.application.exception.AuthServiceUnavailableException;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.ports.identite.GestionIdentitesPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Comptes Keycloak via l'API d'administration, avec le compte de service du
 * client backend (grant client_credentials, rôles realm-management
 * manage-users / view-users / query-users).
 */
@Slf4j
@Component
public class KeycloakIdentitesAdapter implements GestionIdentitesPort {

    private final KeycloakProperties properties;
    private final RestClient restClient;

    private volatile String jetonService;
    private volatile Instant jetonExpireLe = Instant.EPOCH;

    public KeycloakIdentitesAdapter(KeycloakProperties properties, RestClient.Builder builder) {
        this.properties = properties;
        this.restClient = builder.requestFactory(KeycloakHttp.requestFactory()).build();
    }

    @Override
    public String creerCompte(String email, String prenom, String nom, String motDePasse) {
        Map<String, Object> compte = Map.of(
                "username", email,
                "email", email,
                "firstName", prenom,
                "lastName", nom,
                "enabled", true,
                "emailVerified", true,
                "credentials", List.of(Map.of("type", "password", "value", motDePasse, "temporary", false)));
        try {
            ResponseEntity<Void> reponse = restClient.post().uri(properties.usersEndpoint())
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + jetonService())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(compte)
                    .retrieve()
                    .toBodilessEntity();
            URI location = reponse.getHeaders().getLocation();
            if (location != null) {
                String chemin = location.getPath();
                return chemin.substring(chemin.lastIndexOf('/') + 1);
            }
            return trouverParEmail(email).orElseThrow(() ->
                    new AuthServiceUnavailableException("Compte créé mais introuvable.", null));
        } catch (HttpClientErrorException e) {
            if (e.getStatusCode() == HttpStatus.CONFLICT) {
                throw new RegleMetierException("COMPTE_EXISTANT", "Un compte existe déjà avec cette adresse e-mail.");
            }
            if (e.getStatusCode() == HttpStatus.BAD_REQUEST && e.getResponseBodyAsString().contains("assword")) {
                throw new RegleMetierException("MOT_DE_PASSE_REFUSE",
                        "Ce mot de passe ne respecte pas la politique de sécurité.");
            }
            throw indisponible("création de compte", e);
        } catch (RestClientException e) {
            throw indisponible("création de compte", e);
        }
    }

    @Override
    public Optional<String> trouverParEmail(String email) {
        URI uri = UriComponentsBuilder.fromHttpUrl(properties.usersEndpoint())
                .queryParam("email", email)
                .queryParam("exact", true)
                .encode().build().toUri();
        try {
            CompteKeycloak[] comptes = restClient.get().uri(uri)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + jetonService())
                    .retrieve()
                    .body(CompteKeycloak[].class);
            if (comptes == null) return Optional.empty();
            for (CompteKeycloak compte : comptes) {
                if (email.equalsIgnoreCase(compte.email())) return Optional.of(compte.id());
            }
            return Optional.empty();
        } catch (RestClientException e) {
            throw indisponible("recherche de compte", e);
        }
    }

    @Override
    public void definirMotDePasse(String identifiant, String motDePasse) {
        try {
            restClient.put().uri(properties.usersEndpoint() + "/{id}/reset-password", identifiant)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + jetonService())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of("type", "password", "value", motDePasse, "temporary", false))
                    .retrieve()
                    .toBodilessEntity();
        } catch (HttpClientErrorException e) {
            if (e.getStatusCode() == HttpStatus.BAD_REQUEST) {
                throw new RegleMetierException("MOT_DE_PASSE_REFUSE",
                        "Ce mot de passe ne respecte pas la politique de sécurité.");
            }
            throw indisponible("changement de mot de passe", e);
        } catch (RestClientException e) {
            throw indisponible("changement de mot de passe", e);
        }
    }

    @Override
    public void supprimerCompte(String identifiant) {
        try {
            restClient.delete().uri(properties.usersEndpoint() + "/{id}", identifiant)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + jetonService())
                    .retrieve()
                    .toBodilessEntity();
        } catch (HttpClientErrorException.NotFound e) {
            // Déjà supprimé : rien à compenser.
        } catch (RestClientException e) {
            log.error("Compte Keycloak {} orphelin : suppression impossible ({})", identifiant, e.getMessage());
        }
    }

    /** Jeton du compte de service, réutilisé jusqu'à 30 s avant son expiration. */
    private String jetonService() {
        if (jetonService != null && Instant.now().isBefore(jetonExpireLe)) return jetonService;
        synchronized (this) {
            if (jetonService != null && Instant.now().isBefore(jetonExpireLe)) return jetonService;
            MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
            form.add("grant_type", "client_credentials");
            form.add("client_id", properties.clientId());
            form.add("client_secret", properties.clientSecret());
            try {
                JetonService jeton = restClient.post().uri(properties.tokenEndpoint())
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .body(form)
                        .retrieve()
                        .body(JetonService.class);
                if (jeton == null || jeton.accessToken() == null) {
                    throw new AuthServiceUnavailableException("Jeton de service vide.", null);
                }
                jetonService = jeton.accessToken();
                jetonExpireLe = Instant.now().plusSeconds(Math.max(0, jeton.expiresIn() - 30));
                return jetonService;
            } catch (HttpClientErrorException e) {
                log.error("Compte de service Keycloak refusé ({}) : activez « Service accounts » sur le client {} "
                        + "et donnez-lui les rôles realm-management manage-users, view-users, query-users. {}",
                        e.getStatusCode(), properties.clientId(), e.getResponseBodyAsString());
                throw new AuthServiceUnavailableException("Compte de service Keycloak mal configuré.", e);
            } catch (RestClientException e) {
                throw new AuthServiceUnavailableException("Service d'authentification injoignable.", e);
            }
        }
    }

    private AuthServiceUnavailableException indisponible(String operation, RestClientException e) {
        if (e instanceof HttpClientErrorException h && h.getStatusCode() == HttpStatus.FORBIDDEN) {
            log.error("Keycloak refuse la {} : le compte de service du client {} n'a pas les rôles realm-management requis.",
                    operation, properties.clientId());
            jetonService = null;
        } else {
            log.error("Keycloak : échec de la {} : {}", operation, e.getMessage());
        }
        return new AuthServiceUnavailableException("Service d'authentification indisponible.", e);
    }

    private record JetonService(@JsonProperty("access_token") String accessToken,
                                @JsonProperty("expires_in") long expiresIn) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record CompteKeycloak(String id, String email) {
    }
}
