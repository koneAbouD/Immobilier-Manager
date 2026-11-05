package com.tmk.immobilier.infrastructure.stockage;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Connexion au stockage objet (MinIO ou tout service compatible S3). */
@ConfigurationProperties(prefix = "app.stockage")
public record StockageProperties(
        String endpoint,
        String accessKey,
        String secretKey,
        String bucket
) {
}
