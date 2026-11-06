package com.tmk.immobilier.interfaces.rest.loyer;

import com.tmk.immobilier.application.domain.loyer.StatutEcheance;
import com.tmk.immobilier.application.usecases.loyer.EnregistrerPaiementUseCase;
import com.tmk.immobilier.application.usecases.loyer.GenererEcheancesUseCase;
import com.tmk.immobilier.application.usecases.loyer.GetEcheancesUseCase;
import com.tmk.immobilier.application.usecases.loyer.GetPaiementsUseCase;
import com.tmk.immobilier.interfaces.rest.common.PageResponse;
import com.tmk.immobilier.interfaces.rest.loyer.dto.request.PaiementRequest;
import com.tmk.immobilier.interfaces.rest.loyer.dto.response.EcheanceResponse;
import com.tmk.immobilier.interfaces.rest.loyer.dto.response.GenerationEcheancesResponse;
import com.tmk.immobilier.interfaces.rest.loyer.dto.response.PaiementResponse;
import com.tmk.immobilier.interfaces.rest.loyer.mapper.LoyerRestMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

@RestController
@RequestMapping("/api/loyers/echeances")
@RequiredArgsConstructor
@Tag(name = "Loyers — échéances", description = "Loyers dus, mois par mois, et leurs encaissements")
public class EcheanceLoyerController {

    private final GetEcheancesUseCase getEcheancesUseCase;
    private final GenererEcheancesUseCase genererEcheancesUseCase;
    private final EnregistrerPaiementUseCase enregistrerPaiementUseCase;
    private final GetPaiementsUseCase getPaiementsUseCase;
    private final LoyerRestMapper mapper;

    @GetMapping("/page")
    public PageResponse<EcheanceResponse> findPage(
            @RequestParam(required = false) Long bailId,
            @RequestParam(required = false) Long locataireId,
            @RequestParam(required = false) Long immeubleId,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM") YearMonth periode,
            @RequestParam(required = false) StatutEcheance statut,
            @RequestParam(defaultValue = "false") boolean aEncaisser,
            @RequestParam(defaultValue = "false") boolean enRetard,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getEcheancesUseCase
                .executePage(bailId, locataireId, immeubleId, periode, statut, aEncaisser, enRetard, page, size)
                .map(mapper::toResponse));
    }

    @GetMapping("/{id:\\d+}")
    public EcheanceResponse findById(@PathVariable Long id) {
        return mapper.toResponse(getEcheancesUseCase.executeById(id));
    }

    @PostMapping("/generer")
    @Operation(summary = "Émettre les loyers",
            description = "Émet les loyers manquants jusqu'au mois donné (idempotent), pour un bail ou pour "
                    + "tous les baux actifs ; au plus 12 mois d'avance. Sans mois, s'arrête au dernier mois "
                    + "émis automatiquement (le mois courant à partir du 25).")
    public GenerationEcheancesResponse generer(
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM") YearMonth jusquA,
            @RequestParam(required = false) Long bailId) {
        YearMonth mois = jusquA != null ? jusquA : GenererEcheancesUseCase.dernierMoisEmis(LocalDate.now());
        return new GenerationEcheancesResponse(mois, genererEcheancesUseCase.executeManuelle(bailId, mois));
    }

    @PostMapping("/{id}/paiements")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Encaisser un loyer", description = "Paiement total ou partiel, plafonné au reste dû")
    public PaiementResponse encaisser(@PathVariable Long id, @Valid @RequestBody PaiementRequest request) {
        return mapper.toResponse(enregistrerPaiementUseCase.execute(id, mapper.toDomain(request)));
    }

    @GetMapping("/{id}/paiements")
    public List<PaiementResponse> paiements(@PathVariable Long id) {
        return mapper.toPaiementResponseList(getPaiementsUseCase.executeParEcheance(id));
    }
}
