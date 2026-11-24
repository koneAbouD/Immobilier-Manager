package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.infrastructure.organisation.GardeOrganisation;
import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PostLoad;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.TenantId;

/**
 * Entité métier appartenant à une organisation. La colonne n'est jamais
 * renseignée à la main : Hibernate y place l'organisation de la session à
 * l'insertion, et elle ne change plus ensuite.
 */
@Getter
@Setter
@MappedSuperclass
public abstract class AbstractTenantEntity extends AbstractAuditEntity {

    @TenantId
    @Column(name = "organisation_id", nullable = false, updatable = false)
    private Long organisationId;

    protected abstract Object identifiant();

    @PostLoad
    void verifierOrganisation() {
        GardeOrganisation.verifierLecture(getClass(), identifiant(), organisationId);
    }
}
