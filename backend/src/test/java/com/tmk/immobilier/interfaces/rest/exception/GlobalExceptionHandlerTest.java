package com.tmk.immobilier.interfaces.rest.exception;

import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpMethod;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.sql.SQLException;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();
    private final MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/baux");

    private static DataIntegrityViolationException violation(String sqlState, String message) {
        return new DataIntegrityViolationException("could not execute statement",
                new SQLException(message, sqlState));
    }

    @Test
    void routeInconnue_garde404_avecMessageFrancais() {
        var response = handler.handleUnexpected(new NoResourceFoundException(HttpMethod.GET, "v3/api-docs"), request);

        assertThat(response.getStatusCode().value()).isEqualTo(404);
        assertThat(response.getBody().getMessage()).isEqualTo("Ressource introuvable.");
    }

    @Test
    void verbeNonSupporte_garde405() {
        var response = handler.handleUnexpected(new HttpRequestMethodNotSupportedException("GET"), request);

        assertThat(response.getStatusCode().value()).isEqualTo(405);
        assertThat(response.getBody().getMessage()).doesNotContain("Request method");
    }

    @Test
    void exceptionInattendue_resteUne500_sansFuiteDuDetail() {
        var response = handler.handleUnexpected(new RuntimeException("NullPointer dans BailMapper"), request);

        assertThat(response.getStatusCode().value()).isEqualTo(500);
        assertThat(response.getBody().getMessage()).doesNotContain("BailMapper");
    }

    @Test
    void doublon_connu_donneLeMessageMetier() {
        var response = handler.handleDataIntegrity(violation("23505",
                "duplicate key value violates unique constraint \"uk_baux_appartement_actif\""), request);

        assertThat(response.getStatusCode().value()).isEqualTo(409);
        assertThat(response.getBody().getMessage()).isEqualTo("Ce logement a déjà un bail actif.");
        assertThat(response.getBody().getDetails()).containsExactly("contrainte:uk_baux_appartement_actif");
    }

    @Test
    void cleEtrangere_nEstPasPresenteeCommeUnDoublon() {
        var response = handler.handleDataIntegrity(violation("23503",
                "update or delete on table \"locataires\" violates foreign key constraint \"fk_baux_locataire\""),
                request);

        assertThat(response.getStatusCode().value()).isEqualTo(409);
        assertThat(response.getBody().getError()).isEqualTo("REFERENCE_EXISTANTE");
        assertThat(response.getBody().getMessage()).contains("encore utilisé");
    }

    @Test
    void check_renvoie422() {
        var response = handler.handleDataIntegrity(violation("23514",
                "new row violates check constraint \"chk_paiements_montant_positif\""), request);

        assertThat(response.getStatusCode().value()).isEqualTo(422);
        assertThat(response.getBody().getMessage())
                .isEqualTo("Le montant du paiement doit être strictement positif.");
    }

    @Test
    void notNull_renvoie400_avecLaColonneEnDetail() {
        var response = handler.handleDataIntegrity(violation("23502",
                "null value in column \"loyer\" of relation \"baux\" violates not-null constraint"), request);

        assertThat(response.getStatusCode().value()).isEqualTo(400);
        assertThat(response.getBody().getDetails()).containsExactly("colonne:loyer");
    }

    @Test
    void illegalArgument_deBibliotheque_nEstPasExpose() {
        var response = handler.handleIllegalArgument(
                new IllegalArgumentException("No enum constant com.tmk.immobilier.StatutBail.FOO"), request);

        assertThat(response.getStatusCode().value()).isEqualTo(400);
        assertThat(response.getBody().getMessage()).doesNotContain("enum");
    }
}
