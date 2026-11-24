package com.tmk.immobilier.interfaces.rest.plateforme;

import com.tmk.immobilier.application.domain.organisation.PlanAbonnement;
import com.tmk.immobilier.application.domain.organisation.StatutAbonnement;
import com.tmk.immobilier.application.usecases.plateforme.AdministrationPlateformeUseCase;
import com.tmk.immobilier.application.usecases.plateforme.AdministrationPlateformeUseCase.OrganisationSuivie;
import com.tmk.immobilier.interfaces.rest.common.PageResponse;
import com.tmk.immobilier.interfaces.rest.organisation.dto.OrganisationResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/** Back-office de l'éditeur (rôle Keycloak SUPER_ADMIN) : organisations clientes et abonnements. */
@RestController
@RequestMapping("/api/plateforme")
@RequiredArgsConstructor
@Tag(name = "Plateforme", description = "Suivi des organisations clientes (éditeur)")
public class PlateformeController {

    private final AdministrationPlateformeUseCase administration;

    public record AbonnementRequest(@NotNull(message = "La formule est obligatoire.") PlanAbonnement plan,
                                    @NotNull(message = "Le statut est obligatoire.") StatutAbonnement statut,
                                    LocalDate essaiFinLe,
                                    /** Nulle : sans échéance. */
                                    LocalDate abonnementFinLe) {
    }

    @GetMapping("/organisations")
    public PageResponse<OrganisationResponse> organisations(
            @RequestParam(required = false) String recherche,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(administration.lister(recherche, page, size).map(PlateformeController::reponse));
    }

    @PutMapping("/organisations/{id}/abonnement")
    @Operation(summary = "Modifier l'abonnement", description = "Activation après paiement, prolongation d'essai, suspension…")
    public OrganisationResponse modifierAbonnement(@PathVariable Long id, @Valid @RequestBody AbonnementRequest request) {
        return reponse(administration.modifierAbonnement(id, request.plan(), request.statut(), request.essaiFinLe(),
                request.abonnementFinLe()));
    }

    private static OrganisationResponse reponse(OrganisationSuivie suivie) {
        return OrganisationResponse.from(suivie.organisation(), suivie.usage(), null);
    }
}
