package com.tmk.immobilier.interfaces.rest.maintenance.dto.response;

import com.tmk.immobilier.application.domain.maintenance.CategorieMaintenance;
import com.tmk.immobilier.application.domain.maintenance.PrioriteMaintenance;
import com.tmk.immobilier.application.domain.maintenance.StatutMaintenance;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record MaintenanceResponse(
        Long id,
        Long immeubleId,
        String immeubleNom,
        Long appartementId,
        String appartementReference,
        String titre,
        String description,
        CategorieMaintenance categorie,
        PrioriteMaintenance priorite,
        StatutMaintenance statut,
        LocalDate dateSignalement,
        LocalDate datePrevue,
        LocalDate dateRealisation,
        String prestataire,
        BigDecimal coutEstime,
        BigDecimal coutReel,
        String motifAnnulation,
        String annulePar,
        LocalDateTime annuleLe
) {
}
