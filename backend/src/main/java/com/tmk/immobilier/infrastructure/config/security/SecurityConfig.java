package com.tmk.immobilier.infrastructure.config.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tmk.immobilier.application.usecases.organisation.ResoudreAccesUseCase;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.web.authentication.BearerTokenAuthenticationFilter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

/**
 * Règles d'accès. Les rôles d'organisation s'emboîtent
 * (PROPRIETAIRE ⊃ ADMIN ⊃ GESTIONNAIRE ⊃ LECTEUR) : un rôle reçoit aussi les
 * autorités de ceux qu'il inclut (voir {@link ContexteOrganisationFilter}).
 */
@Configuration
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthConverter jwtAuthConverter;
    private final ResoudreAccesUseCase resoudreAccesUseCase;
    private final ObjectMapper objectMapper;

    @Value("${app.cors.allowed-origins:*}")
    private String allowedOrigins;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // Public : documentation, santé, connexion et inscription.
                        .requestMatchers(
                                "/actuator/health/**",
                                "/swagger-ui/**",
                                "/v3/api-docs/**",
                                "/swagger-ui.html",
                                "/api/auth/**"
                        ).permitAll()
                        // Back-office de l'éditeur.
                        .requestMatchers("/api/plateforme/**").hasAuthority(JwtAuthConverter.PREFIXE_REALM + "SUPER_ADMIN")
                        // Profil personnel : toute personne connectée, sans organisation.
                        .requestMatchers("/api/moi", "/api/moi/**").authenticated()
                        // Organisation : l'équipe et les réglages relèvent des administrateurs.
                        .requestMatchers("/api/organisation/membres/**", "/api/organisation/membres").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/organisation/**", "/api/organisation").hasRole("LECTEUR")
                        .requestMatchers("/api/organisation/**", "/api/organisation").hasRole("ADMIN")
                        // Données métier : consultation pour tout membre, écriture à partir
                        // de gestionnaire. La piste d'audit (created_by, annule_par…)
                        // nomme toujours un membre authentifié.
                        .requestMatchers(HttpMethod.GET, "/api/**").hasRole("LECTEUR")
                        .requestMatchers("/api/**").hasRole("GESTIONNAIRE")
                        .anyRequest().authenticated()
                )
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthConverter))
                )
                .addFilterAfter(new ContexteOrganisationFilter(resoudreAccesUseCase, objectMapper),
                        BearerTokenAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        // Tolère les espaces autour des virgules (« a.com, b.com ») dans la variable d'env.
        config.setAllowedOriginPatterns(Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(origin -> !origin.isEmpty())
                .toList());
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of(ContexteOrganisationFilter.ENTETE_ACCES, "Content-Disposition"));
        config.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
