package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.ports.persistence.MembreRepository;
import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import lombok.RequiredArgsConstructor;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

/**
 * Tient la table des utilisateurs alignée sur les jetons Keycloak, et rattache
 * les comptes d'avant le SaaS à l'organisation historique.
 *
 * <p>Appelé à chaque requête authentifiée : n'écrit que si quelque chose a
 * changé, ou pour horodater la dernière connexion au plus une fois par quart
 * d'heure.
 */
@RequiredArgsConstructor
public class ComptesUtilisateurs {

    private static final Duration PAS_DERNIERE_CONNEXION = Duration.ofMinutes(15);

    private final UtilisateurRepository utilisateurRepository;
    private final MembreRepository membreRepository;
    private final OrganisationRepository organisationRepository;

    public Utilisateur synchroniser(IdentiteJeton jeton) {
        LocalDateTime maintenant = LocalDateTime.now();
        Optional<Utilisateur> connu = utilisateurRepository.findByKeycloakId(jeton.keycloakId())
                // Compte créé chez Keycloak avant d'être connu ici (migration) : on
                // le relie par son e-mail, que seul le backend peut attribuer.
                .or(() -> jeton.email() == null ? Optional.empty() : utilisateurRepository.findByEmail(jeton.email()));
        Utilisateur utilisateur = connu.orElseGet(() -> Utilisateur.builder().keycloakId(jeton.keycloakId()).build());

        boolean change = utilisateur.getId() == null
                || !Objects.equals(utilisateur.getKeycloakId(), jeton.keycloakId())
                || (jeton.email() != null && !jeton.email().equalsIgnoreCase(utilisateur.getEmail()))
                || (jeton.prenom() != null && !jeton.prenom().equals(utilisateur.getPrenom()))
                || (jeton.nom() != null && !jeton.nom().equals(utilisateur.getNom()))
                || utilisateur.getDerniereConnexion() == null
                || utilisateur.getDerniereConnexion().isBefore(maintenant.minus(PAS_DERNIERE_CONNEXION));
        if (!change) return utilisateur;

        utilisateur.setKeycloakId(jeton.keycloakId());
        if (jeton.email() != null) utilisateur.setEmail(jeton.email().trim().toLowerCase());
        if (jeton.prenom() != null) utilisateur.setPrenom(jeton.prenom());
        if (jeton.nom() != null) utilisateur.setNom(jeton.nom());
        utilisateur.setDerniereConnexion(maintenant);
        // Première connexion : plusieurs requêtes partent en même temps, une
        // seule ligne doit naître.
        return utilisateur.getId() == null
                ? utilisateurRepository.creerSiAbsent(utilisateur)
                : utilisateurRepository.save(utilisateur);
    }

    /**
     * Adhésions actives de l'utilisateur. Un compte d'avant le SaaS (rôle
     * Keycloak ADMIN ou GESTIONNAIRE) sans adhésion rejoint l'organisation
     * historique : le premier administrateur en devient propriétaire.
     */
    public List<Membre> adhesionsActives(Utilisateur utilisateur, IdentiteJeton jeton) {
        List<Membre> adhesions = membreRepository.findByUtilisateurId(utilisateur.getId());
        if (adhesions.isEmpty()) {
            rattacherHistorique(utilisateur, jeton).ifPresent(adhesions::add);
        }
        return adhesions.stream().filter(Membre::isActif).toList();
    }

    private Optional<Membre> rattacherHistorique(Utilisateur utilisateur, IdentiteJeton jeton) {
        boolean admin = jeton.rolesPlateforme().contains("ADMIN");
        boolean gestionnaire = jeton.rolesPlateforme().contains("GESTIONNAIRE");
        if (!admin && !gestionnaire) return Optional.empty();
        Optional<Organisation> historique = organisationRepository.findHistorique();
        if (historique.isEmpty()) return Optional.empty();
        Long organisationId = historique.get().getId();
        RoleMembre role = !admin ? RoleMembre.GESTIONNAIRE
                : membreRepository.existsByOrganisationIdAndRole(organisationId, RoleMembre.PROPRIETAIRE)
                ? RoleMembre.ADMIN : RoleMembre.PROPRIETAIRE;
        // Idempotent : deux requêtes simultanées ne créent qu'une adhésion.
        return membreRepository.ajouterSiAbsente(Membre.builder()
                .organisationId(organisationId)
                .utilisateur(utilisateur)
                .role(role)
                .actif(true)
                .build());
    }
}
