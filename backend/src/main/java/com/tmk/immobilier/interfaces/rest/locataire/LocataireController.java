package com.tmk.immobilier.interfaces.rest.locataire;

import com.tmk.immobilier.application.domain.locataire.SituationLocataire;
import com.tmk.immobilier.application.usecases.locataire.*;
import com.tmk.immobilier.interfaces.rest.common.PageResponse;
import com.tmk.immobilier.interfaces.rest.locataire.dto.request.LocataireRequest;
import com.tmk.immobilier.interfaces.rest.locataire.dto.response.ComptesSituationsResponse;
import com.tmk.immobilier.interfaces.rest.locataire.dto.response.LocataireResponse;
import com.tmk.immobilier.interfaces.rest.locataire.dto.response.LocataireResumeResponse;
import io.swagger.v3.oas.annotations.Operation;
import com.tmk.immobilier.interfaces.rest.locataire.mapper.LocataireRestMapper;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

import static com.tmk.immobilier.interfaces.rest.common.ReponsesFichier.fichier;

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
    private final GetLocataireResumesUseCase getLocataireResumesUseCase;
    private final DeposerPieceIdentiteUseCase deposerPieceIdentiteUseCase;
    private final GetPieceIdentiteUseCase getPieceIdentiteUseCase;
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

    @GetMapping("/resumes/page")
    @Operation(summary = "Locataires avec leur situation",
            description = "Logement en cours et état des loyers ; les retards en tête, puis par nom")
    public PageResponse<LocataireResumeResponse> findResumes(
            @RequestParam(required = false) String recherche,
            @RequestParam(required = false) SituationLocataire situation,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getLocataireResumesUseCase.executePage(recherche, situation, page, size)
                .map(mapper::toResponse));
    }

    @GetMapping("/resumes/comptes")
    @Operation(summary = "Nombre de locataires par situation", description = "Alimente les filtres de la liste")
    public ComptesSituationsResponse compterSituations(@RequestParam(required = false) String recherche) {
        return mapper.toResponse(getLocataireResumesUseCase.compter(recherche));
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

    @PostMapping(value = "/{id}/piece-identite", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Charger la pièce d'identité",
            description = "PDF ou photo (JPEG, PNG) ; remplace la copie précédemment chargée")
    public LocataireResponse deposerPieceIdentite(@PathVariable Long id,
                                                  @RequestPart("fichier") MultipartFile fichier) throws IOException {
        return mapper.toResponse(deposerPieceIdentiteUseCase.execute(id, fichier.getOriginalFilename(),
                fichier.getContentType(), fichier.getSize(), fichier.getInputStream()));
    }

    @GetMapping("/{id}/piece-identite")
    @Operation(summary = "Télécharger la pièce d'identité")
    public ResponseEntity<InputStreamResource> telechargerPieceIdentite(@PathVariable Long id) {
        return fichier(getPieceIdentiteUseCase.execute(id));
    }
}
