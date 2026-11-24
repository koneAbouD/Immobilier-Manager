package com.tmk.immobilier.infrastructure.config.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tmk.immobilier.application.domain.organisation.AccesOrganisation;
import com.tmk.immobilier.application.domain.organisation.AccesResolu;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.exception.AccesOrganisationException;
import com.tmk.immobilier.application.exception.AuthServiceUnavailableException;
import com.tmk.immobilier.application.usecases.organisation.ResoudreAccesUseCase;
import com.tmk.immobilier.infrastructure.organisation.ContexteOrganisation;
import com.tmk.immobilier.interfaces.rest.exception.ApiError;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * Pose l'organisation de chaque requête métier, après l'authentification par
 * jeton et avant les règles d'autorisation :
 * <ol>
 *   <li>résout l'organisation (en-tête {@value #ENTETE_ORGANISATION} ou adhésion
 *       unique) et vérifie que l'appelant en est membre actif ;</li>
 *   <li>applique l'état de l'abonnement (lecture seule, blocage) ;</li>
 *   <li>remplace les autorités par le rôle de l'adhésion (et ceux qu'il inclut) ;</li>
 *   <li>place l'organisation dans {@link ContexteOrganisation}, effacée en sortie.</li>
 * </ol>
 * Non déclaré en {@code @Component} : il ne doit vivre que dans la chaîne de
 * sécurité, pas une seconde fois dans la chaîne des filtres du conteneur.
 */
@Slf4j
public class ContexteOrganisationFilter extends OncePerRequestFilter {

    public static final String ENTETE_ORGANISATION = "X-Organisation-Id";
    public static final String ENTETE_ACCES = "X-Organisation-Acces";

    /** Chemins hors organisation : authentification, profil personnel, back-office plateforme. */
    private static final String[] HORS_ORGANISATION = {"/api/auth/", "/api/moi", "/api/plateforme/"};

    private final ResoudreAccesUseCase resoudreAcces;
    private final ObjectMapper objectMapper;

    public ContexteOrganisationFilter(ResoudreAccesUseCase resoudreAcces, ObjectMapper objectMapper) {
        this.resoudreAcces = resoudreAcces;
        this.objectMapper = objectMapper;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String chemin = request.getRequestURI().substring(request.getContextPath().length());
        return !chemin.startsWith("/api/") || Arrays.stream(HORS_ORGANISATION).anyMatch(chemin::startsWith);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        if (!(SecurityContextHolder.getContext().getAuthentication() instanceof JwtAuthenticationToken jwtAuth)) {
            // Requête anonyme : les règles d'autorisation la refuseront (401).
            chain.doFilter(request, response);
            return;
        }

        Long organisationDemandee;
        try {
            String entete = request.getHeader(ENTETE_ORGANISATION);
            organisationDemandee = entete == null || entete.isBlank() ? null : Long.valueOf(entete.trim());
        } catch (NumberFormatException e) {
            ecrireErreur(request, response, HttpStatus.BAD_REQUEST, "ORGANISATION_INVALIDE",
                    "En-tête " + ENTETE_ORGANISATION + " invalide.");
            return;
        }

        AccesResolu acces;
        try {
            acces = resoudreAcces.execute(IdentitesJeton.depuis(jwtAuth), organisationDemandee, estEcriture(request));
        } catch (AccesOrganisationException e) {
            HttpStatus statut = switch (e.getMotif()) {
                case LECTURE_SEULE -> HttpStatus.PAYMENT_REQUIRED;
                case ORGANISATION_A_PRECISER -> HttpStatus.BAD_REQUEST;
                default -> HttpStatus.FORBIDDEN;
            };
            ecrireErreur(request, response, statut, e.getMotif().name(), e.getMessage());
            return;
        } catch (AuthServiceUnavailableException e) {
            ecrireErreur(request, response, HttpStatus.SERVICE_UNAVAILABLE, "SERVICE_INDISPONIBLE",
                    "Service momentanément indisponible. Réessayez dans un instant.");
            return;
        }

        Set<GrantedAuthority> autorites = new HashSet<>(jwtAuth.getAuthorities());
        for (RoleMembre role : RoleMembre.values()) {
            if (acces.role().inclut(role)) autorites.add(new SimpleGrantedAuthority("ROLE_" + role.name()));
        }
        SecurityContextHolder.getContext().setAuthentication(
                new JwtAuthenticationToken(jwtAuth.getToken(), autorites, jwtAuth.getName()));
        response.setHeader(ENTETE_ACCES, acces.acces().name());
        if (acces.acces() != AccesOrganisation.COMPLET) {
            log.debug("Organisation {} en {}", acces.organisationId(), acces.acces());
        }

        ContexteOrganisation.definir(new ContexteOrganisation.Contexte(
                acces.organisationId(), acces.utilisateurId(), acces.role()));
        try {
            chain.doFilter(request, response);
        } finally {
            ContexteOrganisation.effacer();
        }
    }

    private static boolean estEcriture(HttpServletRequest request) {
        String methode = request.getMethod();
        return !("GET".equals(methode) || "HEAD".equals(methode) || "OPTIONS".equals(methode));
    }

    private void ecrireErreur(HttpServletRequest request, HttpServletResponse response, HttpStatus statut,
                              String code, String message) throws IOException {
        log.warn("[{} {}] accès organisation refusé ({}) -> {} : {}", request.getMethod(), request.getRequestURI(),
                code, statut.value(), message);
        response.setStatus(statut.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        objectMapper.writeValue(response.getOutputStream(), ApiError.builder()
                .status(statut.value())
                .error(code)
                .message(message)
                .path(request.getRequestURI())
                .timestamp(LocalDateTime.now())
                .build());
    }
}
