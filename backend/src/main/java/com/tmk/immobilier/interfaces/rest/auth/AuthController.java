package com.tmk.immobilier.interfaces.rest.auth;

import com.tmk.immobilier.application.usecases.auth.LoginUseCase;
import com.tmk.immobilier.application.usecases.auth.LogoutUseCase;
import com.tmk.immobilier.application.usecases.auth.RefreshTokenUseCase;
import com.tmk.immobilier.interfaces.rest.auth.dto.LoginRequestDto;
import com.tmk.immobilier.interfaces.rest.auth.dto.RefreshTokenRequestDto;
import com.tmk.immobilier.interfaces.rest.auth.dto.TokenResponseDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Tag(name = "Authentification", description = "Connexion, rafraîchissement et déconnexion (proxy Keycloak)")
public class AuthController {

    private final LoginUseCase loginUseCase;
    private final RefreshTokenUseCase refreshTokenUseCase;
    private final LogoutUseCase logoutUseCase;

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
}
