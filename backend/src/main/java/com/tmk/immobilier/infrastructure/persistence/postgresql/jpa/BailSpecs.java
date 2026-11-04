package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.BailEntity;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

public final class BailSpecs {

    private BailSpecs() {
    }

    public static Specification<BailEntity> byFiltres(Long appartementId, Long locataireId, Long immeubleId,
                                                      StatutBail statut, String recherche) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            var appartement = root.get("appartement");
            var locataire = root.get("locataire");
            if (appartementId != null) predicates.add(cb.equal(appartement.get("id"), appartementId));
            if (locataireId != null) predicates.add(cb.equal(locataire.get("id"), locataireId));
            if (immeubleId != null) predicates.add(cb.equal(appartement.get("immeuble").get("id"), immeubleId));
            if (statut != null) predicates.add(cb.equal(root.get("statut"), statut));
            if (!SpecsUtils.estVide(recherche)) {
                predicates.add(SpecsUtils.contientUnDe(cb, recherche,
                        root.get("reference"), locataire.get("nom"), locataire.get("prenom"),
                        appartement.get("reference"), appartement.get("immeuble").get("nom")));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
    }
}
