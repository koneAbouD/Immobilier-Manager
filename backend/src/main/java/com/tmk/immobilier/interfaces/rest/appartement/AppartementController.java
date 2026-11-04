package com.tmk.immobilier.interfaces.rest.appartement;

import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.usecases.appartement.*;
import com.tmk.immobilier.interfaces.rest.appartement.dto.request.AppartementRequest;
import com.tmk.immobilier.interfaces.rest.appartement.dto.response.AppartementResponse;
import com.tmk.immobilier.interfaces.rest.appartement.mapper.AppartementRestMapper;
import com.tmk.immobilier.interfaces.rest.common.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/appartements")
@RequiredArgsConstructor
@Tag(name = "Appartements", description = "Logements et locaux d'un immeuble")
public class AppartementController {

    private final CreateAppartementUseCase createAppartementUseCase;
    private final UpdateAppartementUseCase updateAppartementUseCase;
    private final DeleteAppartementUseCase deleteAppartementUseCase;
    private final GetAppartementByIdUseCase getAppartementByIdUseCase;
    private final GetAppartementsUseCase getAppartementsUseCase;
    private final AppartementRestMapper mapper;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AppartementResponse create(@Valid @RequestBody AppartementRequest request) {
        return mapper.toResponse(createAppartementUseCase.execute(request.immeubleId(), mapper.toDomain(request)));
    }

    @GetMapping("/page")
    public PageResponse<AppartementResponse> findPage(
            @RequestParam(required = false) Long immeubleId,
            @RequestParam(required = false) StatutAppartement statut,
            @RequestParam(required = false) String recherche,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getAppartementsUseCase
                .executePage(immeubleId, statut, recherche, page, size).map(mapper::toResponse));
    }

    @GetMapping("/{id:\\d+}")
    public AppartementResponse findById(@PathVariable Long id) {
        return mapper.toResponse(getAppartementByIdUseCase.execute(id));
    }

    @PutMapping("/{id}")
    public AppartementResponse update(@PathVariable Long id, @Valid @RequestBody AppartementRequest request) {
        return mapper.toResponse(updateAppartementUseCase.execute(id, mapper.toDomain(request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        deleteAppartementUseCase.execute(id);
        return ResponseEntity.noContent().build();
    }
}
