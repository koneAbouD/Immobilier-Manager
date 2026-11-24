package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.ProfilUtilisateur;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;

/** L'utilisateur connecté et ses organisations : premier appel du mobile après la connexion. */
@RequiredArgsConstructor
public class GetMonProfilUseCase {

    private final ComptesUtilisateurs comptes;

    @Transactional
    public ProfilUtilisateur execute(IdentiteJeton jeton) {
        Utilisateur utilisateur = comptes.synchroniser(jeton);
        List<Membre> adhesions = comptes.adhesionsActives(utilisateur, jeton).stream()
                .sorted(Comparator.comparing(m -> m.getOrganisation().getNom(), String.CASE_INSENSITIVE_ORDER))
                .toList();
        return new ProfilUtilisateur(utilisateur, adhesions, jeton.superAdmin());
    }
}
