package com.tmk.immobilier.infrastructure.persistence.postgresql.mapper;

import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.LocataireEntity;
import org.mapstruct.Mapper;

@Mapper(config = PersistenceMapperConfig.class)
public interface LocatairePersistenceMapper {

    LocataireEntity toEntity(Locataire domain);

    Locataire toDomain(LocataireEntity entity);
}
