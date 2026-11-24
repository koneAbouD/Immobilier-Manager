package com.tmk.immobilier.interfaces.rest.organisation;

import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import com.tmk.immobilier.application.usecases.membre.GestionMembresUseCase;
import com.tmk.immobilier.application.usecases.organisation.GetOrganisationCouranteUseCase;
import com.tmk.immobilier.application.usecases.organisation.GetOrganisationCouranteUseCase.OrganisationCourante;
import com.tmk.immobilier.application.usecases.organisation.LogoOrganisationUseCase;
import com.tmk.immobilier.application.usecases.organisation.UpdateOrganisationUseCase;
import com.tmk.immobilier.application.domain.organisation.NouveauMembre;
import com.tmk.immobilier.interfaces.rest.organisation.dto.*;
import io.swagger.v3.oas.annotations.Operation;
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
import java.util.List;

import static com.tmk.immobilier.interfaces.rest.common.ReponsesFichier.fichier;

/** L'organisation de la requête (en-tête X-Organisation-Id) : identité, abonnement, équipe. */
@RestController
@RequestMapping("/api/organisation")
@RequiredArgsConstructor
@Tag(name = "Organisation", description = "Identité du bailleur, abonnement et équipe de l'organisation courante")
public class OrganisationController {

    private final GetOrganisationCouranteUseCase getOrganisationCouranteUseCase;
    private final UpdateOrganisationUseCase updateOrganisationUseCase;
    private final LogoOrganisationUseCase logoOrganisationUseCase;
    private final GestionMembresUseCase gestionMembresUseCase;
    private final OrganisationCourantePort organisationCourante;

    @GetMapping
    @Operation(summary = "Organisation courante", description = "Identité, formule, état et consommation de l'abonnement")
    public OrganisationResponse courante() {
        return reponse(getOrganisationCouranteUseCase.execute());
    }

    @PutMapping
    @Operation(summary = "Modifier l'identité de l'organisation", description = "Imprimée sur les contrats et quittances")
    public OrganisationResponse modifier(@Valid @RequestBody OrganisationRequest request) {
        updateOrganisationUseCase.execute(Organisation.builder()
                .nom(request.nom())
                .representant(request.representant())
                .email(request.email())
                .telephone(request.telephone())
                .adresse(request.adresse())
                .ville(request.ville())
                .pays(request.pays())
                .devise(request.devise())
                .build());
        return reponse(getOrganisationCouranteUseCase.execute());
    }

    @GetMapping("/logo")
    public ResponseEntity<InputStreamResource> logo() {
        return fichier(logoOrganisationUseCase.lire());
    }

    @PostMapping(value = "/logo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Charger le logo", description = "JPEG ou PNG, 2 Mo au plus")
    public OrganisationResponse deposerLogo(@RequestPart("fichier") MultipartFile fichier) throws IOException {
        logoOrganisationUseCase.deposer(fichier.getContentType(), fichier.getSize(), fichier.getInputStream());
        return reponse(getOrganisationCouranteUseCase.execute());
    }

    @DeleteMapping("/logo")
    public ResponseEntity<Void> supprimerLogo() {
        logoOrganisationUseCase.supprimer();
        return ResponseEntity.noContent().build();
    }

    // ----- Équipe -----

    @GetMapping("/membres")
    public List<MembreResponse> membres() {
        return gestionMembresUseCase.lister().stream().map(MembreResponse::from).toList();
    }

    @PostMapping("/membres")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Ajouter un collaborateur",
            description = "Rattache un compte existant, ou le crée avec un mot de passe provisoire renvoyé une seule fois")
    public MembreResponse ajouterMembre(@Valid @RequestBody MembreRequest request) {
        NouveauMembre nouveau = gestionMembresUseCase.ajouter(request.email(), request.prenom(), request.nom(),
                request.role());
        return MembreResponse.from(nouveau.membre(), nouveau.motDePasseTemporaire());
    }

    @PatchMapping("/membres/{id}")
    @Operation(summary = "Changer le rôle ou (dés)activer un membre")
    public MembreResponse modifierMembre(@PathVariable Long id, @RequestBody ModificationMembreRequest request) {
        return MembreResponse.from(gestionMembresUseCase.modifier(id, request.role(), request.actif()));
    }

    @DeleteMapping("/membres/{id}")
    public ResponseEntity<Void> retirerMembre(@PathVariable Long id) {
        gestionMembresUseCase.retirer(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/membres/{id}/propriete")
    @Operation(summary = "Transmettre la propriété du compte", description = "Réservé au propriétaire, qui devient administrateur")
    public MembreResponse transfererPropriete(@PathVariable Long id) {
        return MembreResponse.from(gestionMembresUseCase.transfererPropriete(id));
    }

    private OrganisationResponse reponse(OrganisationCourante courante) {
        return OrganisationResponse.from(courante.organisation(), courante.usage(),
                courante.monRole() != null ? courante.monRole() : organisationCourante.role().orElse(null));
    }
}
