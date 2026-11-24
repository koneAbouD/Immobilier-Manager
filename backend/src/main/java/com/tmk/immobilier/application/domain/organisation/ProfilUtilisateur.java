package com.tmk.immobilier.application.domain.organisation;

import java.util.List;

/** L'utilisateur connecté et les organisations auxquelles il a accès. */
public record ProfilUtilisateur(Utilisateur utilisateur, List<Membre> adhesions, boolean superAdmin) {
}
