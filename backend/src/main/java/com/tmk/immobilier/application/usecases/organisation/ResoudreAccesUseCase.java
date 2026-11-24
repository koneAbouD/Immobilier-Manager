package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.organisation.AccesOrganisation;
import com.tmk.immobilier.application.domain.organisation.AccesResolu;
import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.exception.AccesOrganisationException;
import com.tmk.immobilier.application.exception.AccesOrganisationException.Motif;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

/**
 * Détermine, pour une requête authentifiée, l'organisation dans laquelle elle
 * s'exécute et ce que l'appelant y peut.
 *
 * <p>Règles : l'organisation demandée (en-tête {@code X-Organisation-Id}) doit
 * être l'une des adhésions actives de l'appelant ; sans en-tête, l'unique
 * adhésion est retenue. Un abonnement échu ou suspendu ne laisse que la
 * consultation ; résilié, plus rien.
 */
@RequiredArgsConstructor
public class ResoudreAccesUseCase {

    private final ComptesUtilisateurs comptes;

    @Transactional
    public AccesResolu execute(IdentiteJeton jeton, Long organisationDemandee, boolean ecriture) {
        Utilisateur utilisateur = comptes.synchroniser(jeton);
        List<Membre> adhesions = comptes.adhesionsActives(utilisateur, jeton);
        if (adhesions.isEmpty()) {
            throw new AccesOrganisationException(Motif.AUCUNE_ORGANISATION,
                    "Votre compte n'est rattaché à aucune organisation active.");
        }

        Membre membre;
        if (organisationDemandee != null) {
            membre = adhesions.stream()
                    .filter(m -> m.getOrganisationId().equals(organisationDemandee))
                    .findFirst()
                    .orElseThrow(() -> new AccesOrganisationException(Motif.NON_MEMBRE,
                            "Vous n'êtes pas membre de cette organisation."));
        } else if (adhesions.size() == 1) {
            membre = adhesions.getFirst();
        } else {
            throw new AccesOrganisationException(Motif.ORGANISATION_A_PRECISER,
                    "Vous appartenez à plusieurs organisations : choisissez celle dans laquelle travailler.");
        }

        Organisation organisation = membre.getOrganisation();
        LocalDate aujourdhui = LocalDate.now();
        AccesOrganisation acces = organisation.acces(aujourdhui);
        String motif = acces == AccesOrganisation.COMPLET ? null : organisation.motifRestriction(aujourdhui);
        if (acces == AccesOrganisation.BLOQUE) {
            throw new AccesOrganisationException(Motif.BLOQUE, motif);
        }
        if (acces == AccesOrganisation.LECTURE_SEULE && ecriture) {
            throw new AccesOrganisationException(Motif.LECTURE_SEULE, motif);
        }
        return new AccesResolu(utilisateur.getId(), organisation.getId(), membre.getRole(), acces, motif);
    }
}
