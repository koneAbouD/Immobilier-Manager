package com.tmk.immobilier.interfaces.rest.maintenance.mapper;

import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.interfaces.rest.common.RestMapperConfig;
import com.tmk.immobilier.interfaces.rest.maintenance.dto.request.MaintenanceRequest;
import com.tmk.immobilier.interfaces.rest.maintenance.dto.response.MaintenanceResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(config = RestMapperConfig.class)
public interface MaintenanceRestMapper {

    @Mapping(target = "id", ignore = true)
    // Résolus par le use case à partir des identifiants.
    @Mapping(target = "immeuble", ignore = true)
    @Mapping(target = "appartement", ignore = true)
    // Cycle de vie : posés par les actions dédiées, jamais par une saisie.
    @Mapping(target = "statut", ignore = true)
    @Mapping(target = "dateRealisation", ignore = true)
    @Mapping(target = "coutReel", ignore = true)
    @Mapping(target = "motifAnnulation", ignore = true)
    @Mapping(target = "annulePar", ignore = true)
    @Mapping(target = "annuleLe", ignore = true)
    Maintenance toDomain(MaintenanceRequest request);

    @Mapping(target = "immeubleId", source = "immeuble.id")
    @Mapping(target = "immeubleNom", source = "immeuble.nom")
    @Mapping(target = "appartementId", source = "appartement.id")
    @Mapping(target = "appartementReference", source = "appartement.reference")
    MaintenanceResponse toResponse(Maintenance domain);
}
