package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.maintenance.PrioriteMaintenance;
import com.tmk.immobilier.application.domain.maintenance.StatutMaintenance;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.MaintenanceEntity;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

public final class MaintenanceSpecs {

    private MaintenanceSpecs() {
    }

    public static Specification<MaintenanceEntity> byFiltres(Long immeubleId, Long appartementId,
                                                             StatutMaintenance statut, PrioriteMaintenance priorite,
                                                             String recherche) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (immeubleId != null) predicates.add(cb.equal(root.get("immeuble").get("id"), immeubleId));
            if (appartementId != null) predicates.add(cb.equal(root.get("appartement").get("id"), appartementId));
            if (statut != null) predicates.add(cb.equal(root.get("statut"), statut));
            if (priorite != null) predicates.add(cb.equal(root.get("priorite"), priorite));
            if (!SpecsUtils.estVide(recherche)) {
                // Jointure externe : une intervention des parties communes n'a pas de logement.
                var appartement = root.join("appartement", JoinType.LEFT);
                predicates.add(SpecsUtils.contientUnDe(cb, recherche,
                        root.get("titre"), root.get("prestataire"), appartement.get("reference")));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
    }
}
