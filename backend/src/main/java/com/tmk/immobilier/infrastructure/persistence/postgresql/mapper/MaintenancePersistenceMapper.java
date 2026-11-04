package com.tmk.immobilier.infrastructure.persistence.postgresql.mapper;

import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.MaintenanceEntity;
import org.mapstruct.Mapper;

@Mapper(config = PersistenceMapperConfig.class,
        uses = {ImmeublePersistenceMapper.class, AppartementPersistenceMapper.class})
public interface MaintenancePersistenceMapper {

    MaintenanceEntity toEntity(Maintenance domain);

    Maintenance toDomain(MaintenanceEntity entity);
}
