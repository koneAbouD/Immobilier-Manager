package com.tmk.immobilier.interfaces.rest.locataire;

import com.tmk.immobilier.application.usecases.locataire.*;
import com.tmk.immobilier.interfaces.rest.common.PageResponse;
import com.tmk.immobilier.interfaces.rest.locataire.dto.request.LocataireRequest;
import com.tmk.immobilier.interfaces.rest.locataire.dto.response.LocataireResponse;
import com.tmk.immobilier.interfaces.rest.locataire.mapper.LocataireRestMapper;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/locataires")
@RequiredArgsConstructor
@Tag(name = "Locataires")
public class LocataireController {

    private final CreateLocataireUseCase createLocataireUseCase;
    private final UpdateLocataireUseCase updateLocataireUseCase;
    private final DeleteLocataireUseCase deleteLocataireUseCase;
    private final GetLocataireByIdUseCase getLocataireByIdUseCase;
    private final GetLocatairesUseCase getLocatairesUseCase;
    private final LocataireRestMapper mapper;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public LocataireResponse create(@Valid @RequestBody LocataireRequest request) {
        return mapper.toResponse(createLocataireUseCase.execute(mapper.toDomain(request)));
    }

    @GetMapping("/page")
    public PageResponse<LocataireResponse> findPage(
            @RequestParam(required = false) String recherche,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getLocatairesUseCase.executePage(recherche, page, size).map(mapper::toResponse));
    }

    @GetMapping("/{id:\\d+}")
    public LocataireResponse findById(@PathVariable Long id) {
        return mapper.toResponse(getLocataireByIdUseCase.execute(id));
    }

    @PutMapping("/{id}")
    public LocataireResponse update(@PathVariable Long id, @Valid @RequestBody LocataireRequest request) {
        return mapper.toResponse(updateLocataireUseCase.execute(id, mapper.toDomain(request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        deleteLocataireUseCase.execute(id);
        return ResponseEntity.noContent().build();
    }
}
