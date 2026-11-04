package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.LocataireEntity;
import org.springframework.data.jpa.domain.Specification;

public final class LocataireSpecs {

    private LocataireSpecs() {
    }

    public static Specification<LocataireEntity> recherche(String recherche) {
        return (root, query, cb) -> SpecsUtils.estVide(recherche) ? cb.conjunction()
                : SpecsUtils.contientUnDe(cb, recherche,
                        root.get("nom"), root.get("prenom"), root.get("telephone"), root.get("email"));
    }
}
