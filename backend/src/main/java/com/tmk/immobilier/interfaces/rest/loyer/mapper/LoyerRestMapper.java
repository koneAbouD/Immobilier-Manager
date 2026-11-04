package com.tmk.immobilier.interfaces.rest.loyer.mapper;

import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;
import com.tmk.immobilier.interfaces.rest.common.RestMapperConfig;
import com.tmk.immobilier.interfaces.rest.loyer.dto.request.PaiementRequest;
import com.tmk.immobilier.interfaces.rest.loyer.dto.response.EcheanceResponse;
import com.tmk.immobilier.interfaces.rest.loyer.dto.response.PaiementResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(config = RestMapperConfig.class, imports = java.time.LocalDate.class)
public interface LoyerRestMapper {

    @Mapping(target = "bailId", source = "bail.id")
    @Mapping(target = "bailReference", source = "bail.reference")
    @Mapping(target = "locataireId", source = "bail.locataire.id")
    @Mapping(target = "locataireNom", expression = "java(domain.getBail().getLocataire().nomComplet())")
    @Mapping(target = "locataireTelephone", source = "bail.locataire.telephone")
    @Mapping(target = "appartementId", source = "bail.appartement.id")
    @Mapping(target = "appartementReference", source = "bail.appartement.reference")
    @Mapping(target = "immeubleNom", source = "bail.appartement.immeuble.nom")
    @Mapping(target = "resteDu", expression = "java(domain.resteDu())")
    @Mapping(target = "enRetard", expression = "java(domain.estEnRetard(LocalDate.now()))")
    EcheanceResponse toResponse(EcheanceLoyer domain);

    @Mapping(target = "echeanceId", source = "echeance.id")
    @Mapping(target = "periode", source = "echeance.periode")
    @Mapping(target = "bailReference", source = "echeance.bail.reference")
    @Mapping(target = "locataireNom", expression = "java(domain.getEcheance().getBail().getLocataire().nomComplet())")
    @Mapping(target = "appartementReference", source = "echeance.bail.appartement.reference")
    @Mapping(target = "immeubleNom", source = "echeance.bail.appartement.immeuble.nom")
    PaiementResponse toResponse(PaiementLoyer domain);

    List<PaiementResponse> toPaiementResponseList(List<PaiementLoyer> domains);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "echeance", ignore = true)
    @Mapping(target = "annule", ignore = true)
    @Mapping(target = "motifAnnulation", ignore = true)
    @Mapping(target = "annulePar", ignore = true)
    @Mapping(target = "annuleLe", ignore = true)
    @Mapping(target = "encaissePar", ignore = true)
    PaiementLoyer toDomain(PaiementRequest request);
}
