package com.tmk.immobilier.infrastructure.persistence.postgresql.mapper;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.BailEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(config = PersistenceMapperConfig.class,
        uses = {AppartementPersistenceMapper.class, LocatairePersistenceMapper.class})
public interface BailPersistenceMapper {

    BailEntity toEntity(Bail domain);

    @Mapping(target = "creeLe", expression = "java(entity.getCreatedAt() != null ? entity.getCreatedAt().toLocalDate() : null)")
    Bail toDomain(BailEntity entity);

    List<Bail> toDomainList(List<BailEntity> entities);
}
