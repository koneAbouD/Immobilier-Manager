package com.tmk.immobilier.infrastructure.persistence.postgresql.mapper;

import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.EcheanceLoyerEntity;
import org.mapstruct.Mapper;

import java.util.List;

@Mapper(config = PersistenceMapperConfig.class, uses = BailPersistenceMapper.class)
public interface EcheanceLoyerPersistenceMapper {

    EcheanceLoyerEntity toEntity(EcheanceLoyer domain);

    List<EcheanceLoyerEntity> toEntityList(List<EcheanceLoyer> domains);

    EcheanceLoyer toDomain(EcheanceLoyerEntity entity);

    List<EcheanceLoyer> toDomainList(List<EcheanceLoyerEntity> entities);
}
