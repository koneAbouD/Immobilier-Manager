package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.ImmeubleEntity;
import org.springframework.data.jpa.domain.Specification;

public final class ImmeubleSpecs {

    private ImmeubleSpecs() {
    }

    public static Specification<ImmeubleEntity> recherche(String recherche) {
        return (root, query, cb) -> SpecsUtils.estVide(recherche) ? cb.conjunction()
                : SpecsUtils.contientUnDe(cb, recherche,
                        root.get("nom"), root.get("commune"), root.get("ville"), root.get("adresse"));
    }
}
