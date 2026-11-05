package com.tmk.immobilier.interfaces.rest.locataire.mapper;

import com.tmk.immobilier.application.domain.locataire.ComptesSituations;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.domain.locataire.LocataireResume;
import com.tmk.immobilier.interfaces.rest.common.RestMapperConfig;
import com.tmk.immobilier.interfaces.rest.locataire.dto.request.LocataireRequest;
import com.tmk.immobilier.interfaces.rest.locataire.dto.response.ComptesSituationsResponse;
import com.tmk.immobilier.interfaces.rest.locataire.dto.response.LocataireResponse;
import com.tmk.immobilier.interfaces.rest.locataire.dto.response.LocataireResumeResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(config = RestMapperConfig.class)
public interface LocataireRestMapper {

    @Mapping(target = "id", ignore = true)
    // La copie de la pièce d'identité se charge à part, jamais par le formulaire.
    @Mapping(target = "pieceCle", ignore = true)
    @Mapping(target = "pieceNom", ignore = true)
    @Mapping(target = "pieceType", ignore = true)
    @Mapping(target = "pieceTaille", ignore = true)
    @Mapping(target = "pieceChargeeLe", ignore = true)
    @Mapping(target = "pieceChargeePar", ignore = true)
    Locataire toDomain(LocataireRequest request);

    @Mapping(target = "nomComplet", expression = "java(domain.nomComplet())")
    @Mapping(target = "pieceChargee", expression = "java(domain.aPieceIdentite())")
    LocataireResponse toResponse(Locataire domain);

    @Mapping(target = "id", source = "locataire.id")
    @Mapping(target = "nom", source = "locataire.nom")
    @Mapping(target = "prenom", source = "locataire.prenom")
    @Mapping(target = "nomComplet", expression = "java(resume.locataire().nomComplet())")
    @Mapping(target = "telephone", source = "locataire.telephone")
    @Mapping(target = "profession", source = "locataire.profession")
    LocataireResumeResponse toResponse(LocataireResume resume);

    @Mapping(target = "total", expression = "java(comptes.total())")
    ComptesSituationsResponse toResponse(ComptesSituations comptes);
}
