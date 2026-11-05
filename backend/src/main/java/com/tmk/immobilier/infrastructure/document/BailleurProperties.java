package com.tmk.immobilier.infrastructure.document;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Identité du bailleur imprimée sur les contrats. */
@ConfigurationProperties(prefix = "app.bailleur")
public record BailleurProperties(
        String nom,
        String representant,
        String adresse,
        String telephone,
        String email,
        /** Ville de signature et juridiction compétente. */
        String ville
) {
}
