package com.tmk.immobilier.interfaces.rest.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record RefreshTokenRequestDto(
        @NotBlank(message = "Le refresh token est obligatoire.") String refreshToken
) {
}
