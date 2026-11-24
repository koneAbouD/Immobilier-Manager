package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.auth.TokenResponse;
import com.tmk.immobilier.application.exception.AuthenticationFailedException;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import com.tmk.immobilier.application.ports.identite.GestionIdentitesPort;
import lombok.RequiredArgsConstructor;

/** Changement de mot de passe par l'utilisateur lui-même, sur présentation de l'actuel. */
@RequiredArgsConstructor
public class ChangerMotDePasseUseCase {

    private final KeycloakAuthPort authPort;
    private final GestionIdentitesPort identites;

    public void execute(String keycloakId, String identifiant, String actuel, String nouveau) {
        MotsDePasse.verifierRobustesse(nouveau);
        if (nouveau.equals(actuel)) {
            throw new RegleMetierException("MOT_DE_PASSE_INCHANGE", "Le nouveau mot de passe doit différer de l'actuel.");
        }
        TokenResponse verification;
        try {
            verification = authPort.login(identifiant, actuel);
        } catch (AuthenticationFailedException e) {
            throw new RegleMetierException("MOT_DE_PASSE_INCORRECT", "Le mot de passe actuel est incorrect.");
        }
        // Session ouverte pour la seule vérification : refermée aussitôt.
        authPort.logout(verification.refreshToken());
        identites.definirMotDePasse(keycloakId, nouveau);
    }
}
