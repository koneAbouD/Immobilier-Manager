package com.tmk.immobilier.infrastructure.organisation;

import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.FiltreOrganisationJpaRepository;
import org.hibernate.cfg.AvailableSettings;
import org.springframework.boot.autoconfigure.orm.jpa.HibernatePropertiesCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Cloisonnement des données par organisation (multi-tenant à colonne
 * discriminante), en trois couches :
 * <ol>
 *   <li>Hibernate {@code @TenantId} filtre requêtes et insertions ;</li>
 *   <li>{@link FiltreOrganisationJpaRepository} fait passer {@code findById}
 *       par ce filtre (sinon chargé par clé, sans contrôle) ;</li>
 *   <li>{@link GardeOrganisation} vérifie toute entité chargée ;</li>
 * </ol>
 * et, en base, des clés étrangères composites (id, organisation_id).
 */
@Configuration
@EnableJpaRepositories(
        basePackages = "com.tmk.immobilier.infrastructure.persistence.postgresql.jpa",
        repositoryBaseClass = FiltreOrganisationJpaRepository.class)
public class HibernateOrganisationConfig {

    @Bean
    public HibernatePropertiesCustomizer organisationTenantCustomizer() {
        OrganisationTenantResolver resolver = new OrganisationTenantResolver();
        return properties -> properties.put(AvailableSettings.MULTI_TENANT_IDENTIFIER_RESOLVER, resolver);
    }
}
