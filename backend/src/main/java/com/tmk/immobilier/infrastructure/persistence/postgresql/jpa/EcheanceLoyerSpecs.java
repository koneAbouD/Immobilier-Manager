package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.loyer.StatutEcheance;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.EcheanceLoyerEntity;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public final class EcheanceLoyerSpecs {

    private EcheanceLoyerSpecs() {
    }

    public static Specification<EcheanceLoyerEntity> byFiltres(Long bailId, Long locataireId, Long immeubleId,
                                                               LocalDate periode, StatutEcheance statut,
                                                               boolean aEncaisser, boolean enRetard,
                                                               LocalDate aujourdhui) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            var bail = root.get("bail");
            if (bailId != null) predicates.add(cb.equal(bail.get("id"), bailId));
            if (locataireId != null) predicates.add(cb.equal(bail.get("locataire").get("id"), locataireId));
            if (immeubleId != null) {
                predicates.add(cb.equal(bail.get("appartement").get("immeuble").get("id"), immeubleId));
            }
            if (periode != null) predicates.add(cb.equal(root.get("periode"), periode));
            if (statut != null) predicates.add(cb.equal(root.get("statut"), statut));
            if (aEncaisser || enRetard) {
                predicates.add(root.get("statut").in(StatutEcheance.A_PAYER, StatutEcheance.PARTIEL));
            }
            if (enRetard) {
                predicates.add(cb.lessThan(root.get("dateEcheance"), aujourdhui));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
    }
}
