package com.tmk.immobilier.infrastructure.persistence.postgresql.mapper;

import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.AbstractAuditEntity;
import org.mapstruct.Builder;
import org.mapstruct.MapperConfig;
import org.mapstruct.Mapping;
import org.mapstruct.MappingInheritanceStrategy;

/**
 * Configuration commune des mappers domaine ↔ entité.
 *
 * <p>Les builders Lombok des entités ne voient pas les champs hérités : ils
 * sont désactivés pour que MapStruct passe par les setters, et que les champs
 * d'audit soient visibles. Ceux-ci appartiennent à l'auditing JPA, jamais au
 * domaine : tout mapping vers une entité les ignore par héritage de ce
 * prototype.
 */
@MapperConfig(
        componentModel = "spring",
        builder = @Builder(disableBuilder = true),
        mappingInheritanceStrategy = MappingInheritanceStrategy.AUTO_INHERIT_FROM_CONFIG
)
public interface PersistenceMapperConfig {

    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "createdBy", ignore = true)
    @Mapping(target = "updatedBy", ignore = true)
    AbstractAuditEntity versEntite(Object domaine);
}
