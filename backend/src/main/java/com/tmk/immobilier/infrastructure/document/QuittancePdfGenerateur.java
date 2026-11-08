package com.tmk.immobilier.infrastructure.document;

import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;
import com.tmk.immobilier.application.ports.document.QuittanceGenerateurPort;
import com.tmk.immobilier.application.usecases.loyer.GenererQuittanceUseCase;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Quittance d'un paiement de loyer : une page, lisible sur un téléphone,
 * au même gabarit que le contrat de bail. Elle atteste la somme reçue, pour
 * quel loyer, et ce qui reste dû sur ce loyer à la date d'édition.
 */
@Component
@EnableConfigurationProperties(BailleurProperties.class)
public class QuittancePdfGenerateur implements QuittanceGenerateurPort {

    private static final Locale FR = Locale.FRANCE;
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("d MMMM yyyy", FR);
    private static final DateTimeFormatter MOIS = DateTimeFormatter.ofPattern("MMMM yyyy", FR);
    private static final Color ACCENT = new Color(0x1F, 0x6F, 0x5C);
    private static final Color GRIS = new Color(0x5F, 0x5E, 0x5A);
    private static final Color FOND = new Color(0xF1, 0xEF, 0xE8);
    private static final Color FOND_ACCENT = new Color(0xE3, 0xF1, 0xEC);

    private final BailleurProperties bailleur;

    private final Font titre = police(16, Font.BOLD, ACCENT);
    private final Font sousTitre = police(9.5f, Font.NORMAL, GRIS);
    private final Font rubrique = police(10.5f, Font.BOLD, ACCENT);
    private final Font texte = police(10, Font.NORMAL, Color.BLACK);
    private final Font gras = police(10, Font.BOLD, Color.BLACK);
    private final Font montant = police(20, Font.BOLD, ACCENT);
    private final Font petit = police(8, Font.NORMAL, GRIS);

    public QuittancePdfGenerateur(BailleurProperties bailleur) {
        this.bailleur = bailleur;
    }

    @Override
    public byte[] generer(PaiementLoyer paiement) {
        ByteArrayOutputStream sortie = new ByteArrayOutputStream();
        Document document = new Document(PageSize.A4, 54, 54, 54, 54);
        try {
            PdfWriter.getInstance(document, sortie);
            document.addTitle(GenererQuittanceUseCase.numero(paiement));
            document.addAuthor(valeur(bailleur.nom()));
            document.open();
            ecrire(document, paiement);
            document.close();
        } catch (DocumentException e) {
            throw new IllegalStateException("Mise en page de la quittance impossible", e);
        }
        return sortie.toByteArray();
    }

    private void ecrire(Document doc, PaiementLoyer paiement) throws DocumentException {
        EcheanceLoyer echeance = paiement.getEcheance();
        Bail bail = echeance.getBail();
        Appartement local = bail.getAppartement();
        Immeuble bien = local.getImmeuble();
        Locataire locataire = bail.getLocataire();
        String mois = majuscule(echeance.getPeriode().format(MOIS));

        Paragraph entete = new Paragraph("QUITTANCE DE LOYER", titre);
        entete.setAlignment(Element.ALIGN_CENTER);
        doc.add(entete);
        Paragraph ref = new Paragraph(String.format("N° Q-%06d  ·  Loyer de %s  ·  Délivrée le %s",
                paiement.getId(), mois, date(LocalDate.now())), sousTitre);
        ref.setAlignment(Element.ALIGN_CENTER);
        ref.setSpacingAfter(16);
        doc.add(ref);

        doc.add(blocParties(
                lignes(valeur(bailleur.nom()),
                        prefixe("Représenté par ", bailleur.representant()),
                        bailleur.adresse(),
                        prefixe("Tél. : ", bailleur.telephone())),
                lignes(locataire.nomComplet(),
                        prefixe("Tél. : ", locataire.getTelephone()),
                        prefixe("E-mail : ", locataire.getEmail()))));

        // La somme reçue, en évidence.
        PdfPTable encadre = new PdfPTable(1);
        encadre.setWidthPercentage(100);
        encadre.setSpacingBefore(6);
        encadre.setSpacingAfter(10);
        PdfPCell cellule = new PdfPCell();
        cellule.setBackgroundColor(FOND_ACCENT);
        cellule.setBorder(Rectangle.NO_BORDER);
        cellule.setPadding(14);
        Paragraph libelle = new Paragraph("Somme reçue", sousTitre);
        libelle.setAlignment(Element.ALIGN_CENTER);
        cellule.addElement(libelle);
        Paragraph somme = new Paragraph(montant(paiement.getMontant()), montant);
        somme.setAlignment(Element.ALIGN_CENTER);
        cellule.addElement(somme);
        Paragraph modeDate = new Paragraph("Le " + date(paiement.getDatePaiement()) + ", " + mode(paiement), texte);
        modeDate.setAlignment(Element.ALIGN_CENTER);
        cellule.addElement(modeDate);
        encadre.addCell(cellule);
        doc.add(encadre);

        Paragraph attestation = new Paragraph(
                "Le bailleur déclare avoir reçu de " + locataire.nomComplet() + " la somme de "
                        + montant(paiement.getMontant()) + " au titre du loyer et des charges de "
                        + mois.toLowerCase(FR) + " pour le local désigné ci-dessous, et lui en donne quittance.",
                texte);
        attestation.setAlignment(Element.ALIGN_JUSTIFIED);
        attestation.setLeading(14);
        attestation.setSpacingAfter(10);
        doc.add(attestation);

        doc.add(new Paragraph("Détail", rubrique));
        BigDecimal reste = echeance.resteDu();
        doc.add(tableau(List.of(
                new String[]{"Bail", bail.getReference()},
                new String[]{"Local", local.getReference() + " · " + libelleType(local)},
                new String[]{"Bien", bien.getNom()},
                new String[]{"Adresse", joindre(", ", bien.getAdresse(), bien.getCommune(), bien.getVille())},
                new String[]{"Période", mois},
                new String[]{"Loyer et charges du mois", montant(echeance.getMontantDu())},
                new String[]{"Total réglé sur ce loyer", montant(echeance.getMontantPaye())},
                new String[]{"Reste dû à ce jour", montant(reste)},
                new String[]{"Référence du paiement", paiement.getReference()})));

        Paragraph solde = new Paragraph(reste.signum() <= 0
                ? "Le loyer de " + mois.toLowerCase(FR) + " est intégralement réglé."
                : "Paiement partiel : il reste " + montant(reste) + " à régler sur le loyer de "
                        + mois.toLowerCase(FR) + ".", gras);
        solde.setSpacingBefore(8);
        solde.setSpacingAfter(18);
        doc.add(solde);

        PdfPTable signature = new PdfPTable(new float[]{1, 1});
        signature.setWidthPercentage(100);
        PdfPCell vide = new PdfPCell(new Phrase(" "));
        vide.setBorder(Rectangle.NO_BORDER);
        signature.addCell(vide);
        PdfPCell signe = new PdfPCell();
        signe.setBorder(Rectangle.NO_BORDER);
        signe.addElement(new Paragraph("Fait à " + valeur(bailleur.ville()) + ", le " + date(LocalDate.now()), texte));
        signe.addElement(new Paragraph("Pour le bailleur, " + valeur(bailleur.nom()), gras));
        if (paiement.getEncaissePar() != null) {
            signe.addElement(new Paragraph("Encaissé par " + paiement.getEncaissePar(), petit));
        }
        signature.addCell(signe);
        doc.add(signature);

        Paragraph note = new Paragraph("Document établi par Immobilier Manager. Le paiement d'un loyer ne vaut pas "
                + "paiement des loyers antérieurs restant dus.", petit);
        note.setSpacingBefore(24);
        doc.add(note);
    }

    // ── Mise en page ────────────────────────────────────────────────────────

    private PdfPTable blocParties(List<String> bailleurLignes, List<String> locataireLignes) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.addCell(cartePartie("BAILLEUR", bailleurLignes));
        table.addCell(cartePartie("LOCATAIRE", locataireLignes));
        return table;
    }

    private PdfPCell cartePartie(String titrePartie, List<String> lignes) {
        PdfPCell cell = new PdfPCell();
        cell.setBackgroundColor(FOND);
        cell.setBorderColor(Color.WHITE);
        cell.setBorderWidth(3);
        cell.setPadding(9);
        cell.addElement(new Paragraph(titrePartie, rubrique));
        for (int i = 0; i < lignes.size(); i++) {
            cell.addElement(new Paragraph(lignes.get(i), i == 0 ? gras : texte));
        }
        return cell;
    }

    private PdfPTable tableau(List<String[]> lignes) throws DocumentException {
        PdfPTable table = new PdfPTable(new float[]{1.5f, 2.5f});
        table.setWidthPercentage(100);
        table.setSpacingBefore(4);
        for (String[] ligne : lignes) {
            if (ligne[1] == null || ligne[1].isBlank()) continue;
            table.addCell(cellule(ligne[0], texte, FOND));
            table.addCell(cellule(ligne[1], gras, Color.WHITE));
        }
        return table;
    }

    private PdfPCell cellule(String contenu, Font font, Color fond) {
        PdfPCell cell = new PdfPCell(new Phrase(contenu, font));
        cell.setBackgroundColor(fond);
        cell.setBorderColor(new Color(0xD3, 0xD1, 0xC7));
        cell.setBorderWidth(0.5f);
        cell.setPadding(6);
        return cell;
    }

    // ── Textes ──────────────────────────────────────────────────────────────

    private static String mode(PaiementLoyer p) {
        if (p.getModePaiement() == null) return "";
        return switch (p.getModePaiement()) {
            case ESPECES -> "en espèces";
            case MOBILE_MONEY -> "par Mobile Money";
            case VIREMENT -> "par virement";
            case CHEQUE -> "par chèque";
        };
    }

    private static String libelleType(Appartement local) {
        if (local.getType() == null) return "Local";
        return switch (local.getType()) {
            case APPARTEMENT -> "Appartement";
            case MAGASIN -> "Magasin";
            case BUREAU -> "Bureau";
            case ENTREPOT -> "Entrepôt";
            case TERRAIN -> "Terrain";
        };
    }

    private static String montant(BigDecimal valeur) {
        NumberFormat format = NumberFormat.getIntegerInstance(FR);
        return format.format(valeur != null ? valeur : BigDecimal.ZERO).replace(' ', ' ').replace(' ', ' ')
                + " FCFA";
    }

    private static String date(LocalDate date) {
        return date != null ? date.format(DATE) : "";
    }

    private static String majuscule(String s) {
        return s.isEmpty() ? s : s.substring(0, 1).toUpperCase(FR) + s.substring(1);
    }

    private static String valeur(String s) {
        return s != null && !s.isBlank() ? s : "________________";
    }

    private static String prefixe(String prefixe, String valeur) {
        return valeur != null && !valeur.isBlank() ? prefixe + valeur : null;
    }

    private static String joindre(String separateur, String... parties) {
        return Stream.of(parties).filter(p -> p != null && !p.isBlank()).collect(Collectors.joining(separateur));
    }

    private static List<String> lignes(String... valeurs) {
        List<String> resultat = new ArrayList<>();
        for (String v : valeurs) if (v != null && !v.isBlank()) resultat.add(v);
        return resultat;
    }

    private static Font police(float taille, int style, Color couleur) {
        return new Font(Font.HELVETICA, taille, style, couleur);
    }
}
