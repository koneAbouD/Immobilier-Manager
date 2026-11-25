package com.tmk.immobilier.application.usecases.journal;

import com.tmk.immobilier.application.domain.journal.ActionJournal;
import com.tmk.immobilier.application.domain.journal.Changement;
import com.tmk.immobilier.application.domain.journal.EntreeJournal;
import com.tmk.immobilier.application.domain.journal.Instantane;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import com.tmk.immobilier.application.ports.persistence.JournalActionsRepository;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import com.tmk.immobilier.application.ports.security.AuteurCourantPort;
import lombok.RequiredArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Consigne les modifications et suppressions dans le journal de l'organisation.
 * Appelé par les use cases, dans leur transaction : la trace et l'opération
 * sont enregistrées ensemble ou pas du tout.
 */
@RequiredArgsConstructor
public class JournalActions {

    private final JournalActionsRepository journal;
    private final OrganisationCourantePort organisationCourante;
    private final UtilisateurRepository utilisateurRepository;
    private final AuteurCourantPort auteurCourant;

    /** Trace une modification ; rien si aucun champ n'a changé. */
    public void modification(TypeEntite type, Long id, String libelle, String contexte,
                             Instantane avant, Instantane apres) {
        List<Changement> changements = Instantane.differences(avant, apres);
        if (changements.isEmpty()) return;
        consigner(ActionJournal.MODIFICATION, type, id, libelle, contexte, changements);
    }

    /** Trace une suppression, avec les dernières valeurs connues de la donnée. */
    public void suppression(TypeEntite type, Long id, String libelle, String contexte, Instantane derniereValeur) {
        consigner(ActionJournal.SUPPRESSION, type, id, libelle, contexte, derniereValeur.enSuppression());
    }

    private void consigner(ActionJournal action, TypeEntite type, Long id, String libelle, String contexte,
                           List<Changement> changements) {
        Optional<Long> auteurId = organisationCourante.utilisateurId();
        String auteurNom = auteurId.flatMap(utilisateurRepository::findById)
                .map(Utilisateur::nomComplet)
                .filter(nom -> !nom.isBlank())
                .orElseGet(auteurCourant::auteur);
        journal.save(EntreeJournal.builder()
                .date(LocalDateTime.now())
                .action(action)
                .typeEntite(type)
                .entiteId(id)
                .libelle(libelle)
                .contexte(contexte)
                .auteurId(auteurId.orElse(null))
                .auteurNom(auteurNom)
                .changements(changements)
                .build());
    }
}
