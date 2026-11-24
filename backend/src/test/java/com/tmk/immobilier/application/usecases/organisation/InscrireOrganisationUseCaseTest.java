package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.auth.TokenResponse;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import com.tmk.immobilier.application.ports.identite.GestionIdentitesPort;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import com.tmk.immobilier.application.usecases.organisation.InscrireOrganisationUseCase.Inscription;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class InscrireOrganisationUseCaseTest {

    @Mock
    private GestionIdentitesPort identites;
    @Mock
    private UtilisateurRepository utilisateurRepository;
    @Mock
    private CreerOrganisationUseCase creerOrganisation;
    @Mock
    private KeycloakAuthPort authPort;
    @InjectMocks
    private InscrireOrganisationUseCase useCase;

    @Test
    void sansEmailLeTelephoneDevientLIdentifiantDeConnexion() {
        when(utilisateurRepository.findByTelephone("0707123456")).thenReturn(Optional.empty());
        when(identites.trouverParIdentifiant("0707123456")).thenReturn(Optional.empty());
        when(identites.creerCompte("0707123456", null, "Awa", "Koné", "Secret2026")).thenReturn("kc-1");
        when(authPort.login("0707123456", "Secret2026")).thenReturn(new TokenResponse("a", "r", 300, 1800, "Bearer"));

        useCase.execute(new Inscription("Agence", "Awa", "Koné", " ", "+225 07 07 12 34 56", "Secret2026"));

        verify(creerOrganisation).execute(eq("Agence"), eq("0707123456"),
                argThat(u -> u.getEmail() == null && "0707123456".equals(u.getTelephone()) && "kc-1".equals(u.getKeycloakId())));
        verify(identites, never()).trouverParEmail(any());
    }

    @Test
    void refuseUnNumeroDejaUtilise() {
        when(utilisateurRepository.findByTelephone("0707123456")).thenReturn(Optional.empty());
        when(identites.trouverParIdentifiant("0707123456")).thenReturn(Optional.of("kc-9"));

        assertThatThrownBy(() -> useCase.execute(new Inscription("A", "B", "C", null, "0707123456", "Secret2026")))
                .isInstanceOf(RegleMetierException.class)
                .hasMessageContaining("numéro de téléphone");
        verify(identites, never()).creerCompte(any(), any(), any(), any(), any());
    }

    @Test
    void refuseUnNumeroInvalide() {
        assertThatThrownBy(() -> useCase.execute(new Inscription("A", "B", "C", null, "abc", "Secret2026")))
                .isInstanceOf(RegleMetierException.class)
                .hasMessageContaining("pas valide");
    }
}
