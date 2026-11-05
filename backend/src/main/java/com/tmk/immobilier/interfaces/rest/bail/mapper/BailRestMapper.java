package com.tmk.immobilier.interfaces.rest.bail.mapper;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.interfaces.rest.bail.dto.request.BailConditionsRequest;
import com.tmk.immobilier.interfaces.rest.bail.dto.request.BailRequest;
import com.tmk.immobilier.interfaces.rest.bail.dto.response.BailResponse;
import com.tmk.immobilier.interfaces.rest.common.RestMapperConfig;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(config = RestMapperConfig.class)
public interface BailRestMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "reference", ignore = true)
    // Résolus par le use case à partir des identifiants.
    @Mapping(target = "appartement", ignore = true)
    @Mapping(target = "locataire", ignore = true)
    // Posés par le cycle de vie du bail, jamais par une saisie.
    @Mapping(target = "statut", ignore = true)
    @Mapping(target = "dateResiliation", ignore = true)
    @Mapping(target = "motifResiliation", ignore = true)
    @Mapping(target = "resiliePar", ignore = true)
    @Mapping(target = "contratGenereLe", ignore = true)
    @Mapping(target = "contratSigneCle", ignore = true)
    @Mapping(target = "contratSigneNom", ignore = true)
    @Mapping(target = "contratSigneType", ignore = true)
    @Mapping(target = "contratSigneTaille", ignore = true)
    @Mapping(target = "contratSigneLe", ignore = true)
    @Mapping(target = "contratSignePar", ignore = true)
    Bail toDomain(BailRequest request);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "reference", ignore = true)
    @Mapping(target = "appartement", ignore = true)
    @Mapping(target = "locataire", ignore = true)
    @Mapping(target = "statut", ignore = true)
    @Mapping(target = "dateResiliation", ignore = true)
    @Mapping(target = "motifResiliation", ignore = true)
    @Mapping(target = "resiliePar", ignore = true)
    @Mapping(target = "contratGenereLe", ignore = true)
    @Mapping(target = "contratSigneCle", ignore = true)
    @Mapping(target = "contratSigneNom", ignore = true)
    @Mapping(target = "contratSigneType", ignore = true)
    @Mapping(target = "contratSigneTaille", ignore = true)
    @Mapping(target = "contratSigneLe", ignore = true)
    @Mapping(target = "contratSignePar", ignore = true)
    Bail toDomain(BailConditionsRequest request);

    @Mapping(target = "appartementId", source = "appartement.id")
    @Mapping(target = "appartementReference", source = "appartement.reference")
    @Mapping(target = "immeubleId", source = "appartement.immeuble.id")
    @Mapping(target = "immeubleNom", source = "appartement.immeuble.nom")
    @Mapping(target = "locataireId", source = "locataire.id")
    @Mapping(target = "locataireNom", expression = "java(domain.getLocataire() != null ? domain.getLocataire().nomComplet() : null)")
    @Mapping(target = "locataireTelephone", source = "locataire.telephone")
    @Mapping(target = "montantMensuel", expression = "java(domain.montantMensuel())")
    @Mapping(target = "statutContrat", expression = "java(domain.statutContrat())")
    BailResponse toResponse(Bail domain);
}
