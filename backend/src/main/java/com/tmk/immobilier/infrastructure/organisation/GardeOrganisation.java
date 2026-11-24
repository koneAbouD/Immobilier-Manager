package com.tmk.immobilier.infrastructure.organisation;

import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import lombok.extern.slf4j.Slf4j;

import java.util.Objects;

/**
 * Dernier rempart du cloisonnement. Le filtre Hibernate couvre les requêtes,
 * mais pas le chargement direct par clé (association paresseuse, merge…) :
 * toute entité métier chargée est donc contrôlée ici. Une ligne d'une autre
 * organisation n'est jamais rendue — l'appelant reçoit « introuvable ».
 */
@Slf4j
public final class GardeOrganisation {

    private GardeOrganisation() {
    }

    public static void verifierLecture(Class<?> type, Object id, Long organisationLigne) {
        Long courante = ContexteOrganisation.organisationIdOuAucune();
        if (!Objects.equals(courante, organisationLigne)) {
            log.warn("Accès inter-organisations bloqué : {} #{} (organisation {}) lu depuis l'organisation {}",
                    type.getSimpleName(), id, organisationLigne, courante);
            throw new ResourceNotFoundException("Élément introuvable.");
        }
    }
}
