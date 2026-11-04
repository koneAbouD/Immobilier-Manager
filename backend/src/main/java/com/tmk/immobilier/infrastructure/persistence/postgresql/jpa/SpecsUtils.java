package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Predicate;

import java.util.Arrays;

/** Briques communes des Specifications de recherche. */
final class SpecsUtils {

    private SpecsUtils() {
    }

    static boolean estVide(String recherche) {
        return recherche == null || recherche.isBlank();
    }

    /** Motif LIKE insensible à la casse, jokers saisis par l'utilisateur neutralisés. */
    static String motif(String recherche) {
        String echappe = recherche.trim().toLowerCase()
                .replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
        return "%" + echappe + "%";
    }

    /** Vrai si l'un des champs contient le mot-clé. */
    @SafeVarargs
    static Predicate contientUnDe(CriteriaBuilder cb, String recherche, Expression<String>... champs) {
        String motif = motif(recherche);
        return cb.or(Arrays.stream(champs)
                .map(champ -> cb.like(cb.lower(champ), motif, '\\'))
                .toArray(Predicate[]::new));
    }
}
