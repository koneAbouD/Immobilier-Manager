package com.tmk.immobilier.application.usecases.membre;

import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.NouveauMembre;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.identite.GestionIdentitesPort;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import com.tmk.immobilier.application.ports.persistence.MembreRepository;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import com.tmk.immobilier.application.usecases.organisation.QuotasAbonnement;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GestionMembresUseCaseTest {

    @Mock
    private OrganisationCourantePort organisationCourante;
    @Mock
    private MembreRepository membreRepository;
    @Mock
    private UtilisateurRepository utilisateurRepository;
    @Mock
    private GestionIdentitesPort identites;
    @Mock
    private QuotasAbonnement quotas;
    @InjectMocks
    private GestionMembresUseCase useCase;

    @BeforeEach
    void setUp() {
        lenient().when(organisationCourante.id()).thenReturn(1L);
        lenient().when(organisationCourante.utilisateurId()).thenReturn(Optional.of(5L));
        lenient().when(organisationCourante.role()).thenReturn(Optional.of(RoleMembre.ADMIN));
    }

    private static Membre membre(long id, long organisationId, long utilisateurId, RoleMembre role) {
        return Membre.builder().id(id).organisationId(organisationId)
                .utilisateur(Utilisateur.builder().id(utilisateurId).email("u" + utilisateurId + "@x.ci").build())
                .role(role).actif(true).build();
    }

    @Test
    void creeLeCompteDUnInconnuAvecUnMotDePasseProvisoire() {
        when(utilisateurRepository.findByEmail("awa@agence.ci")).thenReturn(Optional.empty());
        when(identites.trouverParEmail("awa@agence.ci")).thenReturn(Optional.empty());
        when(identites.creerCompte(eq("awa@agence.ci"), eq("awa@agence.ci"), eq("Awa"), eq("Koné"), anyString())).thenReturn("kc-9");
        when(utilisateurRepository.save(any())).thenAnswer(inv -> {
            Utilisateur u = inv.getArgument(0);
            u.setId(9L);
            return u;
        });
        when(membreRepository.findByOrganisationIdAndUtilisateurId(1L, 9L))
                .thenReturn(Optional.of(membre(90, 1, 9, RoleMembre.GESTIONNAIRE)));

        NouveauMembre nouveau = useCase.ajouter(" Awa@Agence.ci ", "Awa", "Koné", RoleMembre.GESTIONNAIRE);

        assertThat(nouveau.motDePasseTemporaire()).hasSize(12);
        verify(quotas).verifierAjoutMembre();
        verify(membreRepository).save(argThat(m -> m.getOrganisationId() == 1L && m.getRole() == RoleMembre.GESTIONNAIRE));
    }

    @Test
    void annuleLeCompteCreeSiLEnregistrementEchoue() {
        when(utilisateurRepository.findByEmail(anyString())).thenReturn(Optional.empty());
        when(identites.trouverParEmail(anyString())).thenReturn(Optional.empty());
        when(identites.creerCompte(anyString(), anyString(), anyString(), anyString(), anyString())).thenReturn("kc-9");
        when(utilisateurRepository.save(any())).thenThrow(new IllegalStateException("base indisponible"));

        assertThatThrownBy(() -> useCase.ajouter("awa@agence.ci", "Awa", "Koné", RoleMembre.LECTEUR))
                .isInstanceOf(IllegalStateException.class);
        verify(identites).supprimerCompte("kc-9");
    }

    @Test
    void seulLeProprietaireNommeUnAdministrateur() {
        assertThatThrownBy(() -> useCase.ajouter("x@y.ci", "X", "Y", RoleMembre.ADMIN))
                .isInstanceOf(RegleMetierException.class)
                .hasMessageContaining("propriétaire");
        assertThatThrownBy(() -> useCase.ajouter("x@y.ci", "X", "Y", RoleMembre.PROPRIETAIRE))
                .isInstanceOf(RegleMetierException.class);
        verifyNoInteractions(identites);
    }

    @Test
    void leProprietaireEstProtege() {
        when(membreRepository.findById(10L)).thenReturn(Optional.of(membre(10, 1, 7, RoleMembre.PROPRIETAIRE)));

        assertThatThrownBy(() -> useCase.retirer(10L)).isInstanceOf(RegleMetierException.class);
        verify(membreRepository, never()).deleteById(any());
    }

    @Test
    void personneNAgitSurSaPropreAdhesion() {
        when(membreRepository.findById(11L)).thenReturn(Optional.of(membre(11, 1, 5, RoleMembre.ADMIN)));

        assertThatThrownBy(() -> useCase.modifier(11L, RoleMembre.LECTEUR, null))
                .isInstanceOf(RegleMetierException.class);
    }

    @Test
    void unMembreDUneAutreOrganisationEstIntrouvable() {
        when(membreRepository.findById(12L)).thenReturn(Optional.of(membre(12, 2, 8, RoleMembre.GESTIONNAIRE)));

        assertThatThrownBy(() -> useCase.retirer(12L)).isInstanceOf(ResourceNotFoundException.class);
        verify(membreRepository, never()).deleteById(any());
    }

    @Test
    void laProprieteSeTransmetDansLOrdreDeLIndexUnique() {
        when(organisationCourante.role()).thenReturn(Optional.of(RoleMembre.PROPRIETAIRE));
        Membre cible = membre(20, 1, 8, RoleMembre.ADMIN);
        Membre actuel = membre(21, 1, 5, RoleMembre.PROPRIETAIRE);
        when(membreRepository.findById(20L)).thenReturn(Optional.of(cible));
        when(membreRepository.findByOrganisationIdAndUtilisateurId(1L, 5L)).thenReturn(Optional.of(actuel));
        when(membreRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        useCase.transfererPropriete(20L);

        var ordre = inOrder(membreRepository);
        ordre.verify(membreRepository).save(argThat(m -> m.getId() == 21L && m.getRole() == RoleMembre.ADMIN));
        ordre.verify(membreRepository).save(argThat(m -> m.getId() == 20L && m.getRole() == RoleMembre.PROPRIETAIRE));
    }
}
