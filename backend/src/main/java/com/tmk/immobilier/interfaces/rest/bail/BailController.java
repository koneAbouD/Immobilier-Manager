package com.tmk.immobilier.interfaces.rest.bail;

import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.usecases.bail.*;
import com.tmk.immobilier.interfaces.rest.bail.dto.request.BailConditionsRequest;
import com.tmk.immobilier.interfaces.rest.bail.dto.request.BailRequest;
import com.tmk.immobilier.interfaces.rest.bail.dto.request.ResiliationRequest;
import com.tmk.immobilier.interfaces.rest.bail.dto.response.BailResponse;
import com.tmk.immobilier.interfaces.rest.bail.mapper.BailRestMapper;
import com.tmk.immobilier.interfaces.rest.common.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/baux")
@RequiredArgsConstructor
@Tag(name = "Baux", description = "Contrats de location")
public class BailController {

    private final CreateBailUseCase createBailUseCase;
    private final UpdateBailUseCase updateBailUseCase;
    private final ResilierBailUseCase resilierBailUseCase;
    private final GetBailByIdUseCase getBailByIdUseCase;
    private final GetBauxUseCase getBauxUseCase;
    private final BailRestMapper mapper;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Signer un bail",
            description = "Passe le logement en occupé et émet les loyers dus depuis la date de début")
    public BailResponse create(@Valid @RequestBody BailRequest request) {
        return mapper.toResponse(createBailUseCase.execute(
                request.appartementId(), request.locataireId(), mapper.toDomain(request)));
    }

    @GetMapping("/page")
    public PageResponse<BailResponse> findPage(
            @RequestParam(required = false) Long appartementId,
            @RequestParam(required = false) Long locataireId,
            @RequestParam(required = false) Long immeubleId,
            @RequestParam(required = false) StatutBail statut,
            @RequestParam(required = false) String recherche,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getBauxUseCase
                .executePage(appartementId, locataireId, immeubleId, statut, recherche, page, size)
                .map(mapper::toResponse));
    }

    @GetMapping("/{id:\\d+}")
    public BailResponse findById(@PathVariable Long id) {
        return mapper.toResponse(getBailByIdUseCase.execute(id));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Réviser les conditions",
            description = "Les nouvelles conditions s'appliquent aux loyers émis ensuite")
    public BailResponse update(@PathVariable Long id, @Valid @RequestBody BailConditionsRequest request) {
        return mapper.toResponse(updateBailUseCase.execute(id, mapper.toDomain(request)));
    }

    @PatchMapping("/{id}/resilier")
    @Operation(summary = "Résilier le bail",
            description = "Libère le logement et annule les loyers impayés des mois suivant la résiliation")
    public BailResponse resilier(@PathVariable Long id, @Valid @RequestBody ResiliationRequest request) {
        return mapper.toResponse(resilierBailUseCase.execute(id, request.dateResiliation(), request.motif()));
    }
}
