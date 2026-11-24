package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.common.Telephones;
import com.tmk.immobilier.application.domain.auth.TokenResponse;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import com.tmk.immobilier.application.ports.identite.GestionIdentitesPort;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import lombok.RequiredArgsConstructor;

/**
 * Inscription en libre-service : crée le compte de connexion (identifiant =
 * numéro de téléphone, e-mail facultatif), l'organisation (en essai gratuit)
 * et ouvre directement la session.
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
        MotsDePasse.verifierRobustesse(inscription.motDePasse());
        // Le téléphone est l'identifiant de connexion ; l'e-mail est facultatif.
        String telephone = Telephones.canonique(inscription.telephone());
        if (!Telephones.estValide(telephone)) {
            throw new RegleMetierException("TELEPHONE_INVALIDE",
                    "Le numéro de téléphone n'est pas valide (ex. 07 07 12 34 56 ou +33 6 12 34 56 78).");
        }
        String email = inscription.email() == null || inscription.email().isBlank()
                ? null : inscription.email().trim().toLowerCase();

        if (utilisateurRepository.findByTelephone(telephone).isPresent()
                || identites.trouverParIdentifiant(telephone).isPresent()) {
            throw new RegleMetierException("COMPTE_EXISTANT",
                    "Un compte existe déjà avec ce numéro de téléphone. Connectez-vous, ou demandez à "
                            + "l'administrateur de votre organisation de vous y inviter.");
        }
        if (email != null && (utilisateurRepository.findByEmail(email).isPresent()
                || identites.trouverParEmail(email).isPresent())) {
            throw new RegleMetierException("EMAIL_DEJA_UTILISE",
                    "Cette adresse e-mail est déjà liée à un autre compte. Laissez-la vide ou indiquez-en une autre.");
        }
        String prenom = inscription.prenom().trim();
        String nom = inscription.nom().trim();

        String keycloakId = identites.creerCompte(telephone, email, prenom, nom, inscription.motDePasse());
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
        return authPort.login(telephone, inscription.motDePasse());
    }
}
