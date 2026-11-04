package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.PaiementLoyerEntity;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public final class PaiementLoyerSpecs {

    private PaiementLoyerSpecs() {
    }

    public static Specification<PaiementLoyerEntity> byFiltres(Long bailId, Long locataireId, LocalDate dateDebut,
                                                               LocalDate dateFin, Boolean annule) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            var bail = root.get("echeance").get("bail");
            if (bailId != null) predicates.add(cb.equal(bail.get("id"), bailId));
            if (locataireId != null) predicates.add(cb.equal(bail.get("locataire").get("id"), locataireId));
            if (dateDebut != null) predicates.add(cb.greaterThanOrEqualTo(root.get("datePaiement"), dateDebut));
            if (dateFin != null) predicates.add(cb.lessThanOrEqualTo(root.get("datePaiement"), dateFin));
            if (annule != null) predicates.add(cb.equal(root.get("annule"), annule));
            return cb.and(predicates.toArray(Predicate[]::new));
        };
    }
}
