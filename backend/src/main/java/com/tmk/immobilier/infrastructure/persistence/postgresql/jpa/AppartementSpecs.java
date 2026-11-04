package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.AppartementEntity;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

public final class AppartementSpecs {

    private AppartementSpecs() {
    }

    public static Specification<AppartementEntity> byFiltres(Long immeubleId, StatutAppartement statut,
                                                             String recherche) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (immeubleId != null) predicates.add(cb.equal(root.get("immeuble").get("id"), immeubleId));
            if (statut != null) predicates.add(cb.equal(root.get("statut"), statut));
            if (!SpecsUtils.estVide(recherche)) {
                predicates.add(SpecsUtils.contientUnDe(cb, recherche,
                        root.get("reference"), root.get("immeuble").get("nom")));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
    }
}
