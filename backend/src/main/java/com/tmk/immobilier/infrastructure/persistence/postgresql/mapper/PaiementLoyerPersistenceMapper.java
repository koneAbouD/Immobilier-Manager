package com.tmk.immobilier.infrastructure.persistence.postgresql.mapper;

import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.PaiementLoyerEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(config = PersistenceMapperConfig.class, uses = EcheanceLoyerPersistenceMapper.class)
public interface PaiementLoyerPersistenceMapper {

    /**
     * L'auteur de l'encaissement fait l'aller-retour : sans lui, la réponse à
     * une annulation (fusion d'une entité détachée) le perdrait. La colonne
     * n'étant pas modifiable, la valeur relue ne réécrit jamais la base.
     */
    @Mapping(target = "createdBy", source = "encaissePar")
    PaiementLoyerEntity toEntity(PaiementLoyer domain);

    @Mapping(target = "encaissePar", source = "createdBy")
    PaiementLoyer toDomain(PaiementLoyerEntity entity);

    List<PaiementLoyer> toDomainList(List<PaiementLoyerEntity> entities);
}
