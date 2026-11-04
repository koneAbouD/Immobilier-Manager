package com.tmk.immobilier.infrastructure.config.security;

import com.tmk.immobilier.application.ports.security.AuteurCourantPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** Même source que l'auditing JPA : un seul nom d'auteur dans toute la base. */
@Component
@RequiredArgsConstructor
public class AuteurCourantAdapter implements AuteurCourantPort {

    private final SecurityAuditorAware auditorAware;

    @Override
    public String auteur() {
        return auditorAware.getCurrentAuditor().orElse(SecurityAuditorAware.AUTEUR_SYSTEME);
    }
}
