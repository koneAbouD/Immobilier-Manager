package com.tmk.immobilier.interfaces.rest.loyer;

import com.tmk.immobilier.application.usecases.loyer.AnnulerPaiementUseCase;
import com.tmk.immobilier.application.usecases.loyer.GetPaiementsUseCase;
import com.tmk.immobilier.interfaces.rest.common.AnnulationRequest;
import com.tmk.immobilier.interfaces.rest.common.PageResponse;
import com.tmk.immobilier.interfaces.rest.loyer.dto.response.PaiementResponse;
import com.tmk.immobilier.interfaces.rest.loyer.mapper.LoyerRestMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/loyers/paiements")
@RequiredArgsConstructor
@Tag(name = "Loyers — paiements")
public class PaiementLoyerController {

    private final GetPaiementsUseCase getPaiementsUseCase;
    private final AnnulerPaiementUseCase annulerPaiementUseCase;
    private final LoyerRestMapper mapper;

    @GetMapping("/page")
    public PageResponse<PaiementResponse> findPage(
            @RequestParam(required = false) Long bailId,
            @RequestParam(required = false) Long locataireId,
            @RequestParam(required = false) LocalDate dateDebut,
            @RequestParam(required = false) LocalDate dateFin,
            @RequestParam(required = false) Boolean annule,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getPaiementsUseCase
                .executePage(bailId, locataireId, dateDebut, dateFin, annule, page, size)
                .map(mapper::toResponse));
    }

    @PatchMapping("/{id}/annuler")
    @Operation(summary = "Annuler un paiement",
            description = "Le paiement reste tracé ; l'échéance redevient due du montant annulé")
    public PaiementResponse annuler(@PathVariable Long id, @Valid @RequestBody AnnulationRequest request) {
        return mapper.toResponse(annulerPaiementUseCase.execute(id, request.motif()));
    }
}
