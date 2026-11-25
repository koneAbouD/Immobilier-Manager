package com.tmk.immobilier.infrastructure.document;

import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.parser.PdfTextExtractor;
import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.appartement.TypeLogement;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.UsageBail;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class ContratBailPdfGenerateurTest {

    private final ContratBailPdfGenerateur generateur = new ContratBailPdfGenerateur(new LogoBailleur(null));

    private String texte(UsageBail usage, TypeLogement type) throws Exception {
        Bail bail = Bail.builder()
                .reference("BAIL-00001")
                .usage(usage)
                .appartement(Appartement.builder().reference("A1").type(type)
                        .immeuble(Immeuble.builder().nom("Résidence").build()).build())
                .locataire(Locataire.builder().nom("Koné").prenom("Awa").build())
                .dateDebut(LocalDate.of(2026, 12, 1))
                .loyerMensuel(new BigDecimal("150000"))
                .build();
        bail.initializeDefaults();
        PdfReader reader = new PdfReader(generateur.generer(bail, Organisation.builder().nom("TMK").build()));
        PdfTextExtractor extracteur = new PdfTextExtractor(reader);
        StringBuilder sb = new StringBuilder();
        for (int p = 1; p <= reader.getNumberOfPages(); p++) sb.append(extracteur.getTextFromPage(p)).append('\n');
        return sb.toString().replaceAll("\\s+", " ");
    }

    @Test
    void leBailDHabitationSuitLeModeleHabitation() throws Exception {
        String texte = texte(UsageBail.HABITATION, TypeLogement.APPARTEMENT);

        assertThat(texte).contains("CONTRAT DE BAIL À USAGE D'HABITATION")
                .contains("à usage exclusif d'habitation")
                .contains("un mois à l'avance")
                .doesNotContain("six mois");
    }

    @Test
    void leBailProfessionnelSuitLeModeleProfessionnelMemeDansUnAppartement() throws Exception {
        String texte = texte(UsageBail.PROFESSIONNEL, TypeLogement.APPARTEMENT);

        assertThat(texte).contains("CONTRAT DE BAIL À USAGE PROFESSIONNEL")
                .contains("à usage exclusif professionnel")
                .contains("six mois à l'avance")
                .contains("impôts, taxes");
    }

    @Test
    void leBailProfessionnelPreciseLActiviteSelonLeLocal() throws Exception {
        assertThat(texte(UsageBail.PROFESSIONNEL, TypeLogement.MAGASIN)).contains("professionnel (activité commerciale)");
    }
}
