package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.support.JpaEntityInformation;
import org.springframework.data.jpa.repository.support.SimpleJpaRepository;

import java.io.Serializable;
import java.util.Optional;

/**
 * Base de tous les repositories JPA. {@code EntityManager.find} ne passe pas
 * par le filtre d'organisation d'Hibernate : la recherche par identifiant est
 * donc réécrite en requête Criteria, filtrée comme les autres. Un identifiant
 * d'une autre organisation donne « absent », exactement comme un identifiant
 * inexistant.
 */
public class FiltreOrganisationJpaRepository<T, ID extends Serializable> extends SimpleJpaRepository<T, ID> {

    private final JpaEntityInformation<T, ?> information;

    public FiltreOrganisationJpaRepository(JpaEntityInformation<T, ?> information, EntityManager entityManager) {
        super(information, entityManager);
        this.information = information;
    }

    @Override
    public Optional<T> findById(ID id) {
        String attributId = information.getRequiredIdAttribute().getName();
        Specification<T> parId = (root, query, cb) -> cb.equal(root.get(attributId), id);
        return findOne(parId);
    }

    @Override
    public T getReferenceById(ID id) {
        return findById(id).orElseThrow(() -> new EntityNotFoundException(
                information.getJavaType().getSimpleName() + " introuvable : " + id));
    }

    @Override
    @SuppressWarnings("deprecation")
    public T getById(ID id) {
        return getReferenceById(id);
    }

    @Override
    @SuppressWarnings("deprecation")
    public T getOne(ID id) {
        return getReferenceById(id);
    }
}
