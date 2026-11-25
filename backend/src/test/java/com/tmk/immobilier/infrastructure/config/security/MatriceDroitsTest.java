package com.tmk.immobilier.infrastructure.config.security;

import com.tmk.immobilier.application.domain.organisation.AccesOrganisation;
import com.tmk.immobilier.application.domain.organisation.AccesResolu;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.usecases.appartement.*;
import com.tmk.immobilier.application.usecases.immeuble.*;
import com.tmk.immobilier.application.usecases.locataire.*;
import com.tmk.immobilier.application.usecases.organisation.ResoudreAccesUseCase;
import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.usecases.journal.GetJournalActionsUseCase;
import com.tmk.immobilier.interfaces.rest.appartement.AppartementController;
import com.tmk.immobilier.interfaces.rest.journal.JournalController;
import com.tmk.immobilier.interfaces.rest.appartement.mapper.AppartementRestMapper;
import com.tmk.immobilier.interfaces.rest.immeuble.ImmeubleController;
import com.tmk.immobilier.interfaces.rest.immeuble.mapper.ImmeubleRestMapper;
import com.tmk.immobilier.interfaces.rest.locataire.LocataireController;
import com.tmk.immobilier.interfaces.rest.locataire.mapper.LocataireRestMapper;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpMethod;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.request;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Matrice des droits sur les biens, locaux et locataires : qui peut consulter
 * et supprimer quoi. À garder alignée avec `ActionMetier` côté mobile.
 */
@WebMvcTest(controllers = {ImmeubleController.class, AppartementController.class, LocataireController.class,
        JournalController.class})
@Import({SecurityConfig.class, JwtAuthConverter.class})
class MatriceDroitsTest {

    @Autowired
    private MockMvc mvc;

    @MockBean private ResoudreAccesUseCase resoudreAcces;
    @MockBean private JwtDecoder jwtDecoder;
    @MockBean private LimiteurInscriptions limiteurInscriptions;

    @MockBean private CreateImmeubleUseCase createImmeuble;
    @MockBean private UpdateImmeubleUseCase updateImmeuble;
    @MockBean private DeleteImmeubleUseCase deleteImmeuble;
    @MockBean private GetImmeubleByIdUseCase getImmeuble;
    @MockBean private GetImmeublesUseCase getImmeubles;
    @MockBean private AjouterPhotoBienUseCase ajouterPhoto;
    @MockBean private PhotosBienUseCase photos;
    @MockBean private ImmeubleRestMapper immeubleMapper;

    @MockBean private CreateAppartementUseCase createAppartement;
    @MockBean private UpdateAppartementUseCase updateAppartement;
    @MockBean private DeleteAppartementUseCase deleteAppartement;
    @MockBean private GetAppartementByIdUseCase getAppartement;
    @MockBean private GetAppartementsUseCase getAppartements;
    @MockBean private AppartementRestMapper appartementMapper;

    @MockBean private CreateLocataireUseCase createLocataire;
    @MockBean private UpdateLocataireUseCase updateLocataire;
    @MockBean private DeleteLocataireUseCase deleteLocataire;
    @MockBean private GetLocataireByIdUseCase getLocataire;
    @MockBean private GetLocatairesUseCase getLocataires;
    @MockBean private GetLocataireResumesUseCase getResumes;
    @MockBean private DeposerPieceIdentiteUseCase deposerPiece;
    @MockBean private GetPieceIdentiteUseCase getPiece;
    @MockBean private LocataireRestMapper locataireMapper;

    @MockBean private GetJournalActionsUseCase getJournal;

    @ParameterizedTest(name = "{0} {1} en {2} → {3}")
    @CsvSource({
            // Bien : suppression réservée aux administrateurs.
            "DELETE, /api/immeubles/1, LECTEUR, 403",
            "DELETE, /api/immeubles/1, GESTIONNAIRE, 403",
            "DELETE, /api/immeubles/1, ADMIN, 204",
            "DELETE, /api/immeubles/1, PROPRIETAIRE, 204",
            // Photo d'un bien : affaire courante du gestionnaire.
            "DELETE, /api/immeubles/1/photos/2, LECTEUR, 403",
            "DELETE, /api/immeubles/1/photos/2, GESTIONNAIRE, 204",
            // Local : suppression réservée aux administrateurs.
            "DELETE, /api/appartements/1, LECTEUR, 403",
            "DELETE, /api/appartements/1, GESTIONNAIRE, 403",
            "DELETE, /api/appartements/1, ADMIN, 204",
            // Locataire : le gestionnaire corrige ses erreurs de saisie.
            "DELETE, /api/locataires/1, LECTEUR, 403",
            "DELETE, /api/locataires/1, GESTIONNAIRE, 204",
            "DELETE, /api/locataires/1, ADMIN, 204",
            // État de suppression : consultable par tout membre.
            "GET, /api/immeubles/1/suppression, LECTEUR, 200",
            "GET, /api/appartements/1/suppression, LECTEUR, 200",
            "GET, /api/locataires/1/suppression, LECTEUR, 200",
            // Journal des actions : supervision réservée aux administrateurs.
            "GET, /api/journal/page, LECTEUR, 403",
            "GET, /api/journal/page, GESTIONNAIRE, 403",
            "GET, /api/journal/page, ADMIN, 200",
            "GET, /api/journal/page, PROPRIETAIRE, 200",
    })
    void matrice(String methode, String chemin, RoleMembre role, int attendu) throws Exception {
        when(resoudreAcces.execute(any(), any(), anyBoolean()))
                .thenReturn(new AccesResolu(1L, 1L, role, AccesOrganisation.COMPLET, null));
        when(getJournal.execute(any(), any(), any(), anyInt(), anyInt()))
                .thenReturn(new PageResult<>(java.util.List.of(), 0, 20, 0));

        mvc.perform(request(HttpMethod.valueOf(methode), chemin).with(jwt()))
                .andExpect(status().is(attendu));
    }
}
