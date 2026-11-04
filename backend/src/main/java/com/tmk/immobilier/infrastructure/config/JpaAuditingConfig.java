package com.tmk.immobilier.infrastructure.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

/** Horodatage automatique des entités et auteur des écritures — voir {@code SecurityAuditorAware}. */
@Configuration
@EnableJpaAuditing(auditorAwareRef = "securityAuditorAware")
public class JpaAuditingConfig {
}
