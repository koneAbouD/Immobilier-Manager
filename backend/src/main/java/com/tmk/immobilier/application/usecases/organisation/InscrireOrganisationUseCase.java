package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.auth.TokenResponse;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import com.tmk.immobilier.application.ports.identite.GestionIdentitesPort;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import com.tmk.immobilier.application.usecases.locataire.TelephoneNormalizer;
import lombok.RequiredArgsConstructor;

/**
 * Inscription en libre-service : crée le compte de connexion, l'organisation
 * (en essai gratuit) et ouvre directement la session.
 *
 * <p>Le compte Keycloak est créé avant la transaction : s'il ne peut pas l'être,
 * rien n'est écrit ; si l'écriture en base échoue ensuite, il est supprimé
 * (compensation), pour qu'aucun compte orphelin ne bloque une nouvelle tentative.
 */
@RequiredArgsConstructor
public class InscrireOrganisationUseCase {

    public record Inscription(String organisation, String prenom, String nom, String email, String telephone,
                              String motDePasse) {
    }

    private final GestionIdentitesPort identites;
    private final UtilisateurRepository utilisateurRepository;
    private final CreerOrganisationUseCase creerOrganisation;
    private final KeycloakAuthPort authPort;

    public TokenResponse execute(Inscription inscription) {
        String email = inscription.email().trim().toLowerCase();
        MotsDePasse.verifierRobustesse(inscription.motDePasse());
        if (utilisateurRepository.findByEmail(email).isPresent() || identites.trouverParEmail(email).isPresent()) {
            throw new RegleMetierException("COMPTE_EXISTANT",
                    "Un compte existe déjà avec cette adresse e-mail. Connectez-vous, ou demandez à "
                            + "l'administrateur de votre organisation de vous y inviter.");
        }
        String prenom = inscription.prenom().trim();
        String nom = inscription.nom().trim();
        String telephone = inscription.telephone() == null || inscription.telephone().isBlank()
                ? null : TelephoneNormalizer.normaliser(inscription.telephone());

        String keycloakId = identites.creerCompte(email, prenom, nom, inscription.motDePasse());
        try {
            creerOrganisation.execute(inscription.organisation(), telephone, Utilisateur.builder()
                    .keycloakId(keycloakId)
                    .email(email)
                    .prenom(prenom)
                    .nom(nom)
                    .telephone(telephone)
                    .build());
        } catch (RuntimeException e) {
            identites.supprimerCompte(keycloakId);
            throw e;
        }
        return authPort.login(email, inscription.motDePasse());
    }
}
