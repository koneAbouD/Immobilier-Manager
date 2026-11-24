package com.tmk.immobilier.interfaces.rest.auth;

import com.tmk.immobilier.application.usecases.auth.LoginUseCase;
import com.tmk.immobilier.application.usecases.auth.LogoutUseCase;
import com.tmk.immobilier.application.usecases.auth.RefreshTokenUseCase;
import com.tmk.immobilier.application.domain.organisation.PlanAbonnement;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.usecases.organisation.InscrireOrganisationUseCase;
import com.tmk.immobilier.infrastructure.config.security.LimiteurInscriptions;
import com.tmk.immobilier.interfaces.rest.auth.dto.InscriptionRequest;
import com.tmk.immobilier.interfaces.rest.auth.dto.LoginRequestDto;
import com.tmk.immobilier.interfaces.rest.auth.dto.PlanResponse;
import com.tmk.immobilier.interfaces.rest.auth.dto.RefreshTokenRequestDto;
import com.tmk.immobilier.interfaces.rest.auth.dto.TokenResponseDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Tag(name = "Authentification", description = "Inscription, connexion, rafraîchissement et déconnexion (proxy Keycloak)")
public class AuthController {

    private final LoginUseCase loginUseCase;
    private final RefreshTokenUseCase refreshTokenUseCase;
    private final LogoutUseCase logoutUseCase;
    private final InscrireOrganisationUseCase inscrireOrganisationUseCase;
    private final LimiteurInscriptions limiteurInscriptions;

    @PostMapping("/inscription")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Créer un compte organisation",
            description = "Crée l'organisation (essai gratuit), son propriétaire, et ouvre la session")
    public TokenResponseDto inscription(@Valid @RequestBody InscriptionRequest request, HttpServletRequest http) {
        if (!limiteurInscriptions.autoriser(adresseClient(http))) {
            throw new RegleMetierException("TROP_DE_TENTATIVES",
                    "Trop d'inscriptions depuis cette connexion. Réessayez dans une heure.");
        }
        return TokenResponseDto.from(inscrireOrganisationUseCase.execute(new InscrireOrganisationUseCase.Inscription(
                request.organisation(), request.prenom(), request.nom(), request.email(), request.telephone(),
                request.motDePasse())));
    }

    @GetMapping("/plans")
    @Operation(summary = "Formules d'abonnement")
    public List<PlanResponse> plans() {
        return Arrays.stream(PlanAbonnement.values()).map(PlanResponse::from).toList();
    }

    @PostMapping("/login")
    @Operation(summary = "Connexion", description = "Authentifie un utilisateur et retourne les tokens JWT")
    public TokenResponseDto login(@Valid @RequestBody LoginRequestDto request) {
        return TokenResponseDto.from(loginUseCase.execute(request.username(), request.password()));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Rafraîchir le token")
    public TokenResponseDto refresh(@Valid @RequestBody RefreshTokenRequestDto request) {
        return TokenResponseDto.from(refreshTokenUseCase.execute(request.refreshToken()));
    }

    @PostMapping("/logout")
    @Operation(summary = "Déconnexion", description = "Invalide la session Keycloak")
    public ResponseEntity<Void> logout(@Valid @RequestBody RefreshTokenRequestDto request) {
        logoutUseCase.execute(request.refreshToken());
        return ResponseEntity.noContent().build();
    }

    /** Adresse du client ; derrière nginx, la première de X-Forwarded-For. */
    private static String adresseClient(HttpServletRequest http) {
        String transmis = http.getHeader("X-Forwarded-For");
        if (transmis != null && !transmis.isBlank()) return transmis.split(",")[0].trim();
        return http.getRemoteAddr();
    }
}
