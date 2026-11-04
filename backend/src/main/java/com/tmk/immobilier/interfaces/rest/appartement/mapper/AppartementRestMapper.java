package com.tmk.immobilier.interfaces.rest.appartement.mapper;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.interfaces.rest.appartement.dto.request.AppartementRequest;
import com.tmk.immobilier.interfaces.rest.appartement.dto.response.AppartementResponse;
import com.tmk.immobilier.interfaces.rest.common.RestMapperConfig;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(config = RestMapperConfig.class)
public interface AppartementRestMapper {

    @Mapping(target = "id", ignore = true)
    // Résolu par le use case à partir de immeubleId.
    @Mapping(target = "immeuble", ignore = true)
    Appartement toDomain(AppartementRequest request);

    @Mapping(target = "immeubleId", source = "immeuble.id")
    @Mapping(target = "immeubleNom", source = "immeuble.nom")
    AppartementResponse toResponse(Appartement domain);

    List<AppartementResponse> toResponseList(List<Appartement> domains);
}
