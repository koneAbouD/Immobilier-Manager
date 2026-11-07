package com.tmk.immobilier.interfaces.rest.immeuble.mapper;

import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.immeuble.PhotoBien;
import com.tmk.immobilier.interfaces.rest.common.RestMapperConfig;
import com.tmk.immobilier.interfaces.rest.immeuble.dto.request.ImmeubleRequest;
import com.tmk.immobilier.interfaces.rest.immeuble.dto.response.ImmeubleResponse;
import com.tmk.immobilier.interfaces.rest.immeuble.dto.response.PhotoBienResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(config = RestMapperConfig.class)
public interface ImmeubleRestMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "occupation", ignore = true)
    Immeuble toDomain(ImmeubleRequest request);

    @Mapping(target = "nombreAppartements", source = "occupation.nombreAppartements", defaultValue = "0")
    @Mapping(target = "nombreOccupes", source = "occupation.nombreOccupes", defaultValue = "0")
    @Mapping(target = "nombreLibres", source = "occupation.nombreLibres", defaultValue = "0")
    ImmeubleResponse toResponse(Immeuble domain);

    List<ImmeubleResponse> toResponseList(List<Immeuble> domains);

    PhotoBienResponse toResponse(PhotoBien photo);

    List<PhotoBienResponse> toPhotoResponseList(List<PhotoBien> photos);
}
