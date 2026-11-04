package com.tmk.immobilier.interfaces.rest.immeuble;

import com.tmk.immobilier.application.usecases.immeuble.*;
import com.tmk.immobilier.interfaces.rest.common.PageResponse;
import com.tmk.immobilier.interfaces.rest.immeuble.dto.request.ImmeubleRequest;
import com.tmk.immobilier.interfaces.rest.immeuble.dto.response.ImmeubleResponse;
import com.tmk.immobilier.interfaces.rest.immeuble.mapper.ImmeubleRestMapper;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/immeubles")
@RequiredArgsConstructor
@Tag(name = "Immeubles")
public class ImmeubleController {

    private final CreateImmeubleUseCase createImmeubleUseCase;
    private final UpdateImmeubleUseCase updateImmeubleUseCase;
    private final DeleteImmeubleUseCase deleteImmeubleUseCase;
    private final GetImmeubleByIdUseCase getImmeubleByIdUseCase;
    private final GetImmeublesUseCase getImmeublesUseCase;
    private final ImmeubleRestMapper mapper;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ImmeubleResponse create(@Valid @RequestBody ImmeubleRequest request) {
        return mapper.toResponse(createImmeubleUseCase.execute(mapper.toDomain(request)));
    }

    /** Liste complète, pour alimenter les sélecteurs. */
    @GetMapping
    public List<ImmeubleResponse> findAll() {
        return mapper.toResponseList(getImmeublesUseCase.execute());
    }

    @GetMapping("/page")
    public PageResponse<ImmeubleResponse> findPage(
            @RequestParam(required = false) String recherche,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getImmeublesUseCase.executePage(recherche, page, size).map(mapper::toResponse));
    }

    @GetMapping("/{id:\\d+}")
    public ImmeubleResponse findById(@PathVariable Long id) {
        return mapper.toResponse(getImmeubleByIdUseCase.execute(id));
    }

    @PutMapping("/{id}")
    public ImmeubleResponse update(@PathVariable Long id, @Valid @RequestBody ImmeubleRequest request) {
        updateImmeubleUseCase.execute(id, mapper.toDomain(request));
        return mapper.toResponse(getImmeubleByIdUseCase.execute(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        deleteImmeubleUseCase.execute(id);
        return ResponseEntity.noContent().build();
    }
}
