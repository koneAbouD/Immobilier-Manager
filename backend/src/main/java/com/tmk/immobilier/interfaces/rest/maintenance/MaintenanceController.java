package com.tmk.immobilier.interfaces.rest.maintenance;

import com.tmk.immobilier.application.domain.maintenance.PrioriteMaintenance;
import com.tmk.immobilier.application.domain.maintenance.StatutMaintenance;
import com.tmk.immobilier.application.usecases.maintenance.*;
import com.tmk.immobilier.interfaces.rest.common.AnnulationRequest;
import com.tmk.immobilier.interfaces.rest.common.PageResponse;
import com.tmk.immobilier.interfaces.rest.maintenance.dto.request.MaintenanceRequest;
import com.tmk.immobilier.interfaces.rest.maintenance.dto.request.TerminerMaintenanceRequest;
import com.tmk.immobilier.interfaces.rest.maintenance.dto.response.MaintenanceResponse;
import com.tmk.immobilier.interfaces.rest.maintenance.mapper.MaintenanceRestMapper;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/maintenances")
@RequiredArgsConstructor
@Tag(name = "Maintenances")
public class MaintenanceController {

    private final SignalerMaintenanceUseCase signalerMaintenanceUseCase;
    private final UpdateMaintenanceUseCase updateMaintenanceUseCase;
    private final DemarrerMaintenanceUseCase demarrerMaintenanceUseCase;
    private final TerminerMaintenanceUseCase terminerMaintenanceUseCase;
    private final AnnulerMaintenanceUseCase annulerMaintenanceUseCase;
    private final DeleteMaintenanceUseCase deleteMaintenanceUseCase;
    private final GetMaintenancesUseCase getMaintenancesUseCase;
    private final MaintenanceRestMapper mapper;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public MaintenanceResponse signaler(@Valid @RequestBody MaintenanceRequest request) {
        return mapper.toResponse(signalerMaintenanceUseCase.execute(
                request.immeubleId(), request.appartementId(), mapper.toDomain(request)));
    }

    @GetMapping("/page")
    public PageResponse<MaintenanceResponse> findPage(
            @RequestParam(required = false) Long immeubleId,
            @RequestParam(required = false) Long appartementId,
            @RequestParam(required = false) StatutMaintenance statut,
            @RequestParam(required = false) PrioriteMaintenance priorite,
            @RequestParam(required = false) String recherche,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getMaintenancesUseCase
                .executePage(immeubleId, appartementId, statut, priorite, recherche, page, size)
                .map(mapper::toResponse));
    }

    @GetMapping("/{id:\\d+}")
    public MaintenanceResponse findById(@PathVariable Long id) {
        return mapper.toResponse(getMaintenancesUseCase.executeById(id));
    }

    @PutMapping("/{id}")
    public MaintenanceResponse update(@PathVariable Long id, @Valid @RequestBody MaintenanceRequest request) {
        return mapper.toResponse(updateMaintenanceUseCase.execute(
                id, request.immeubleId(), request.appartementId(), mapper.toDomain(request)));
    }

    @PatchMapping("/{id}/demarrer")
    public MaintenanceResponse demarrer(@PathVariable Long id) {
        return mapper.toResponse(demarrerMaintenanceUseCase.execute(id));
    }

    @PatchMapping("/{id}/terminer")
    public MaintenanceResponse terminer(@PathVariable Long id,
                                        @Valid @RequestBody TerminerMaintenanceRequest request) {
        return mapper.toResponse(terminerMaintenanceUseCase.execute(id, request.coutReel(), request.dateRealisation()));
    }

    @PatchMapping("/{id}/annuler")
    public MaintenanceResponse annuler(@PathVariable Long id, @Valid @RequestBody AnnulationRequest request) {
        return mapper.toResponse(annulerMaintenanceUseCase.execute(id, request.motif()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        deleteMaintenanceUseCase.execute(id);
        return ResponseEntity.noContent().build();
    }
}
