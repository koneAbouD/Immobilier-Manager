package com.tmk.immobilier.infrastructure.config.security;

import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Jeton Keycloak → authentification Spring.
 *
 * <p>Les rôles du realm deviennent des autorités {@code REALM_*} (ex.
 * {@code REALM_SUPER_ADMIN}) et ne donnent, à eux seuls, aucun droit sur les
 * données : les rôles {@code ROLE_*} (PROPRIETAIRE, ADMIN, GESTIONNAIRE,
 * LECTEUR) viennent de l'adhésion à l'organisation, posés ensuite par
 * {@link ContexteOrganisationFilter}.
 */
@Component
public class JwtAuthConverter implements Converter<Jwt, AbstractAuthenticationToken> {

    public static final String PREFIXE_REALM = "REALM_";

    @Override
    public AbstractAuthenticationToken convert(Jwt jwt) {
        return new JwtAuthenticationToken(jwt, rolesRealm(jwt).stream()
                .map(role -> (GrantedAuthority) new SimpleGrantedAuthority(PREFIXE_REALM + role))
                .collect(Collectors.toSet()), nomAffiche(jwt));
    }

    /** Nom archivé dans la piste d'audit : identifiant de connexion (l'e-mail pour les comptes SaaS). */
    static String nomAffiche(Jwt jwt) {
        String username = jwt.getClaimAsString("preferred_username");
        return username != null ? username : jwt.getSubject();
    }

    @SuppressWarnings("unchecked")
    public static Set<String> rolesRealm(Jwt jwt) {
        Map<String, Object> realmAccess = jwt.getClaimAsMap("realm_access");
        if (realmAccess == null || !(realmAccess.get("roles") instanceof Collection<?> roles)) {
            return Set.of();
        }
        return ((Collection<Object>) roles).stream()
                .map(r -> String.valueOf(r).toUpperCase())
                .collect(Collectors.toUnmodifiableSet());
    }

    public static List<String> rolesRealm(Collection<? extends GrantedAuthority> autorites) {
        return autorites.stream()
                .map(GrantedAuthority::getAuthority)
                .filter(a -> a.startsWith(PREFIXE_REALM))
                .map(a -> a.substring(PREFIXE_REALM.length()))
                .toList();
    }
}
