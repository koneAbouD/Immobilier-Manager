package com.tmk.immobilier.infrastructure.persistence.postgresql.mapper;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.AppartementEntity;
import org.mapstruct.Mapper;

import java.util.List;

@Mapper(config = PersistenceMapperConfig.class, uses = ImmeublePersistenceMapper.class)
public interface AppartementPersistenceMapper {

    AppartementEntity toEntity(Appartement domain);

    Appartement toDomain(AppartementEntity entity);

    List<Appartement> toDomainList(List<AppartementEntity> entities);
}
