package com.tmk.immobilier.interfaces.rest.moi;

import com.tmk.immobilier.application.domain.organisation.AccesOrganisation;
import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.ProfilUtilisateur;
import com.tmk.immobilier.application.usecases.organisation.ChangerMotDePasseUseCase;
import com.tmk.immobilier.application.usecases.organisation.GetMonProfilUseCase;
import com.tmk.immobilier.application.usecases.organisation.IdentiteJeton;
import com.tmk.immobilier.infrastructure.config.security.IdentitesJeton;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/** L'utilisateur connecté, indépendamment de toute organisation. */
@RestController
@RequestMapping("/api/moi")
@RequiredArgsConstructor
@Tag(name = "Mon compte", description = "Profil, organisations accessibles et mot de passe")
public class MoiController {

    private final GetMonProfilUseCase getMonProfilUseCase;
    private final ChangerMotDePasseUseCase changerMotDePasseUseCase;

    public record AdhesionResponse(Long organisationId, String organisation, String role, String statutAbonnement,
                                   String acces) {
    }

    public record ProfilResponse(Long id, String email, String telephone, String prenom, String nom, String nomComplet,
                                 boolean superAdmin, List<AdhesionResponse> organisations) {
    }

    public record MotDePasseRequest(@NotBlank(message = "Le mot de passe actuel est obligatoire.") String actuel,
                                    @NotBlank(message = "Le nouveau mot de passe est obligatoire.") String nouveau) {
    }

    @GetMapping
    @Operation(summary = "Mon profil", description = "À appeler après la connexion : organisations accessibles et rôle dans chacune")
    public ProfilResponse profil(Authentication authentication) {
        ProfilUtilisateur profil = getMonProfilUseCase.execute(IdentitesJeton.depuis(authentication));
        LocalDate aujourdhui = LocalDate.now();
        return new ProfilResponse(profil.utilisateur().getId(), profil.utilisateur().getEmail(),
                profil.utilisateur().getTelephone(),
                profil.utilisateur().getPrenom(), profil.utilisateur().getNom(), profil.utilisateur().nomComplet(),
                profil.superAdmin(),
                profil.adhesions().stream().map(m -> adhesion(m, aujourdhui)).toList());
    }

    @PutMapping("/mot-de-passe")
    @Operation(summary = "Changer mon mot de passe")
    public ResponseEntity<Void> changerMotDePasse(@Valid @RequestBody MotDePasseRequest request,
                                                  Authentication authentication) {
        IdentiteJeton jeton = IdentitesJeton.depuis(authentication);
        changerMotDePasseUseCase.execute(jeton.keycloakId(), authentication.getName(), request.actuel(), request.nouveau());
        return ResponseEntity.noContent().build();
    }

    private static AdhesionResponse adhesion(Membre m, LocalDate aujourdhui) {
        AccesOrganisation acces = m.getOrganisation().acces(aujourdhui);
        return new AdhesionResponse(m.getOrganisationId(), m.getOrganisation().getNom(), m.getRole().name(),
                m.getOrganisation().getStatutAbonnement().name(), acces.name());
    }
}
