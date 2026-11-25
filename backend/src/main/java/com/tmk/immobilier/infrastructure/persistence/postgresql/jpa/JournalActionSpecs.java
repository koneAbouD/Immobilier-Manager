package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.application.domain.journal.ActionJournal;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.JournalActionEntity;
import org.springframework.data.jpa.domain.Specification;

public final class JournalActionSpecs {

    private JournalActionSpecs() {
    }

    public static Specification<JournalActionEntity> filtre(TypeEntite type, ActionJournal action, String recherche) {
        return (root, query, cb) -> cb.and(
                type == null ? cb.conjunction() : cb.equal(root.get("typeEntite"), type),
                action == null ? cb.conjunction() : cb.equal(root.get("action"), action),
                SpecsUtils.estVide(recherche) ? cb.conjunction()
                        : SpecsUtils.contientUnDe(cb, recherche,
                                root.get("libelle"), root.get("contexte"), root.get("auteurNom")));
    }
}
