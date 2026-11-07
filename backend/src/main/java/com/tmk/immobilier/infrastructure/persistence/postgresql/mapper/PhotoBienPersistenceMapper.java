package com.tmk.immobilier.infrastructure.persistence.postgresql.mapper;

import com.tmk.immobilier.application.domain.immeuble.PhotoBien;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.PhotoBienEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(config = PersistenceMapperConfig.class)
public interface PhotoBienPersistenceMapper {

    PhotoBienEntity toEntity(PhotoBien domain);

    @Mapping(target = "ajouteeLe", source = "createdAt")
    @Mapping(target = "ajouteePar", source = "createdBy")
    PhotoBien toDomain(PhotoBienEntity entity);
}
