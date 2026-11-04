package com.tmk.immobilier.interfaces.rest.locataire.mapper;

import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.interfaces.rest.common.RestMapperConfig;
import com.tmk.immobilier.interfaces.rest.locataire.dto.request.LocataireRequest;
import com.tmk.immobilier.interfaces.rest.locataire.dto.response.LocataireResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(config = RestMapperConfig.class)
public interface LocataireRestMapper {

    @Mapping(target = "id", ignore = true)
    Locataire toDomain(LocataireRequest request);

    @Mapping(target = "nomComplet", expression = "java(domain.nomComplet())")
    LocataireResponse toResponse(Locataire domain);
}
