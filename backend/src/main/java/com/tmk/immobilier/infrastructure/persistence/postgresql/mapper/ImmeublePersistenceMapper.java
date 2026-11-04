package com.tmk.immobilier.infrastructure.persistence.postgresql.mapper;

import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.ImmeubleEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(config = PersistenceMapperConfig.class)
public interface ImmeublePersistenceMapper {

    ImmeubleEntity toEntity(Immeuble domain);

    // Occupation calculée par les use cases de lecture : aucune source ici.
    @Mapping(target = "occupation", ignore = true)
    Immeuble toDomain(ImmeubleEntity entity);

    List<Immeuble> toDomainList(List<ImmeubleEntity> entities);
}
