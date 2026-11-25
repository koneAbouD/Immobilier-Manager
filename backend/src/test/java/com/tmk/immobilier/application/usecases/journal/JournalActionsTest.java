package com.tmk.immobilier.application.usecases.journal;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.domain.appartement.TypeLogement;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JournalActionsTest {

    @Mock private JournalActionsRepository repository;
    @Mock private OrganisationCourantePort organisationCourante;
    @Mock private UtilisateurRepository utilisateurRepository;
    @Mock private AuteurCourantPort auteurCourant;
    @InjectMocks private JournalActions journal;

    private static Appartement local(BigDecimal loyer, String description) {
        return Appartement.builder().id(7L).reference("A3").type(TypeLogement.APPARTEMENT)
                .immeuble(Immeuble.builder().nom("Résidence Palmiers").build())
                .loyerMensuel(loyer).statut(StatutAppartement.LIBRE).description(description).build();
    }

    @Test
    void modification_trace_seulementLesChampsChanges_enClair() {
        when(organisationCourante.utilisateurId()).thenReturn(Optional.of(3L));
        when(utilisateurRepository.findById(3L))
                .thenReturn(Optional.of(Utilisateur.builder().prenom("Awa").nom("Koné").build()));

        Appartement avant = local(new BigDecimal("150000"), "Vue mer");
        Appartement apres = local(new BigDecimal("175000"), "  Vue mer ");
        journal.modification(TypeEntite.LOCAL, 7L, "A3", InstantanesMetier.contexte(apres),
                InstantanesMetier.de(avant), InstantanesMetier.de(apres));

        ArgumentCaptor<EntreeJournal> trace = ArgumentCaptor.forClass(EntreeJournal.class);
        verify(repository).save(trace.capture());
        EntreeJournal e = trace.getValue();
        assertThat(e.getAction()).isEqualTo(ActionJournal.MODIFICATION);
        assertThat(e.getContexte()).isEqualTo("Résidence Palmiers");
        assertThat(e.getAuteurNom()).isEqualTo("Awa Koné");
        // Les espaces autour de la description ne comptent pas comme une modification.
        assertThat(e.getChangements())
                .containsExactly(new Changement("Loyer mensuel", "150 000 FCFA", "175 000 FCFA"));
    }

    @Test
    void modification_sansChangement_neTraceRien() {
        Appartement a = local(new BigDecimal("150000"), null);
        journal.modification(TypeEntite.LOCAL, 7L, "A3", null, InstantanesMetier.de(a), InstantanesMetier.de(a));
        verifyNoInteractions(repository);
    }

    @Test
    void suppression_garde_lesDernieresValeursRenseignees_etRetombeSurLIdentifiantTechnique() {
        when(organisationCourante.utilisateurId()).thenReturn(Optional.empty());
        when(auteurCourant.auteur()).thenReturn("system");

        journal.suppression(TypeEntite.BIEN, 1L, "Villa", null,
                new Instantane().avec("Nom", "Villa").avec("Adresse", " ").avec("Type", "Immeuble"));

        ArgumentCaptor<EntreeJournal> trace = ArgumentCaptor.forClass(EntreeJournal.class);
        verify(repository).save(trace.capture());
        assertThat(trace.getValue().getAuteurNom()).isEqualTo("system");
        assertThat(trace.getValue().getChangements()).containsExactly(
                new Changement("Nom", "Villa", null), new Changement("Type", "Immeuble", null));
    }
}
