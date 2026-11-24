package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.organisation.AccesOrganisation;
import com.tmk.immobilier.application.domain.organisation.AccesResolu;
import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.PlanAbonnement;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.domain.organisation.StatutAbonnement;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.exception.AccesOrganisationException;
import com.tmk.immobilier.application.exception.AccesOrganisationException.Motif;
import com.tmk.immobilier.application.ports.persistence.MembreRepository;
import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ResoudreAccesUseCaseTest {

    @Mock
    private UtilisateurRepository utilisateurRepository;
    @Mock
    private MembreRepository membreRepository;
    @Mock
    private OrganisationRepository organisationRepository;

    private ResoudreAccesUseCase useCase;

    private final Utilisateur moi = Utilisateur.builder().id(5L).keycloakId("kc-5").email("moi@agence.ci")
            .prenom("Awa").nom("Koné").derniereConnexion(LocalDateTime.now()).build();

    @BeforeEach
    void setUp() {
        useCase = new ResoudreAccesUseCase(new ComptesUtilisateurs(utilisateurRepository, membreRepository,
                organisationRepository));
        lenient().when(utilisateurRepository.findByKeycloakId("kc-5")).thenReturn(Optional.of(moi));
    }

    private static IdentiteJeton jeton(String... roles) {
        return new IdentiteJeton("kc-5", "moi@agence.ci", "Awa", "Koné", Set.of(roles));
    }

    private static Membre adhesion(long organisationId, RoleMembre role, StatutAbonnement statut) {
        Organisation organisation = Organisation.builder().id(organisationId).nom("Org " + organisationId)
                .plan(PlanAbonnement.ESSENTIEL).statutAbonnement(statut)
                .essaiFinLe(LocalDate.now().plusDays(10)).build();
        return Membre.builder().id(organisationId * 10).organisationId(organisationId).organisation(organisation)
                .role(role).actif(true).build();
    }

    @Test
    void retientLUniqueAdhesionSansEnTete() {
        when(membreRepository.findByUtilisateurId(5L))
                .thenReturn(new ArrayList<>(List.of(adhesion(1, RoleMembre.GESTIONNAIRE, StatutAbonnement.ACTIF))));

        AccesResolu acces = useCase.execute(jeton(), null, true);

        assertThat(acces.organisationId()).isEqualTo(1L);
        assertThat(acces.role()).isEqualTo(RoleMembre.GESTIONNAIRE);
        assertThat(acces.acces()).isEqualTo(AccesOrganisation.COMPLET);
        // Profil à jour et dernière connexion récente : aucune écriture.
        verify(utilisateurRepository, never()).save(any());
    }

    @Test
    void exigeLeChoixQuandPlusieursAdhesions() {
        when(membreRepository.findByUtilisateurId(5L)).thenReturn(new ArrayList<>(List.of(
                adhesion(1, RoleMembre.ADMIN, StatutAbonnement.ACTIF),
                adhesion(2, RoleMembre.LECTEUR, StatutAbonnement.ACTIF))));

        assertThatThrownBy(() -> useCase.execute(jeton(), null, false))
                .isInstanceOf(AccesOrganisationException.class)
                .extracting(e -> ((AccesOrganisationException) e).getMotif())
                .isEqualTo(Motif.ORGANISATION_A_PRECISER);

        assertThat(useCase.execute(jeton(), 2L, false).role()).isEqualTo(RoleMembre.LECTEUR);
    }

    @Test
    void refuseUneOrganisationDontOnNEstPasMembre() {
        when(membreRepository.findByUtilisateurId(5L))
                .thenReturn(new ArrayList<>(List.of(adhesion(1, RoleMembre.PROPRIETAIRE, StatutAbonnement.ACTIF))));

        assertThatThrownBy(() -> useCase.execute(jeton(), 99L, false))
                .isInstanceOf(AccesOrganisationException.class)
                .extracting(e -> ((AccesOrganisationException) e).getMotif())
                .isEqualTo(Motif.NON_MEMBRE);
    }

    @Test
    void ignoreLesAdhesionsDesactivees() {
        Membre desactive = adhesion(1, RoleMembre.GESTIONNAIRE, StatutAbonnement.ACTIF);
        desactive.setActif(false);
        when(membreRepository.findByUtilisateurId(5L)).thenReturn(new ArrayList<>(List.of(desactive)));

        assertThatThrownBy(() -> useCase.execute(jeton(), 1L, false))
                .isInstanceOf(AccesOrganisationException.class)
                .extracting(e -> ((AccesOrganisationException) e).getMotif())
                .isEqualTo(Motif.AUCUNE_ORGANISATION);
    }

    @Test
    void unAbonnementSuspenduNeLaissePlusQueLaLecture() {
        when(membreRepository.findByUtilisateurId(5L))
                .thenReturn(new ArrayList<>(List.of(adhesion(1, RoleMembre.ADMIN, StatutAbonnement.SUSPENDU))));

        assertThat(useCase.execute(jeton(), null, false).acces()).isEqualTo(AccesOrganisation.LECTURE_SEULE);
        assertThatThrownBy(() -> useCase.execute(jeton(), null, true))
                .isInstanceOf(AccesOrganisationException.class)
                .extracting(e -> ((AccesOrganisationException) e).getMotif())
                .isEqualTo(Motif.LECTURE_SEULE);
    }

    @Test
    void unAbonnementResilieBloqueTout() {
        when(membreRepository.findByUtilisateurId(5L))
                .thenReturn(new ArrayList<>(List.of(adhesion(1, RoleMembre.PROPRIETAIRE, StatutAbonnement.RESILIE))));

        assertThatThrownBy(() -> useCase.execute(jeton(), null, false))
                .isInstanceOf(AccesOrganisationException.class)
                .extracting(e -> ((AccesOrganisationException) e).getMotif())
                .isEqualTo(Motif.BLOQUE);
    }

    @Test
    void unAdministrateurDAvantLeSaasDevientProprietaireDeLOrganisationHistorique() {
        Membre rattache = adhesion(1, RoleMembre.PROPRIETAIRE, StatutAbonnement.ACTIF);
        when(membreRepository.findByUtilisateurId(5L)).thenReturn(new ArrayList<>());
        when(organisationRepository.findHistorique())
                .thenReturn(Optional.of(Organisation.builder().id(1L).historique(true).build()));
        when(membreRepository.existsByOrganisationIdAndRole(1L, RoleMembre.PROPRIETAIRE)).thenReturn(false);
        when(membreRepository.findByOrganisationIdAndUtilisateurId(1L, 5L)).thenReturn(Optional.of(rattache));

        AccesResolu acces = useCase.execute(jeton("ADMIN"), null, true);

        assertThat(acces.role()).isEqualTo(RoleMembre.PROPRIETAIRE);
        verify(membreRepository).save(argThat(m -> m.getRole() == RoleMembre.PROPRIETAIRE && m.getOrganisationId() == 1L));
    }

    @Test
    void unCompteSansRoleHistoriqueNeRejointRien() {
        when(membreRepository.findByUtilisateurId(5L)).thenReturn(new ArrayList<>());

        assertThatThrownBy(() -> useCase.execute(jeton(), null, false))
                .isInstanceOf(AccesOrganisationException.class);
        verify(organisationRepository, never()).findHistorique();
        verify(membreRepository, never()).save(any());
    }
}
