package com.tmk.immobilier.infrastructure.document;

import com.lowagie.text.Chunk;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.ColumnText;
import com.lowagie.text.pdf.PdfContentByte;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfPageEventHelper;
import com.lowagie.text.pdf.PdfWriter;
import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.appartement.TypeLogement;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.ports.document.ContratBailGenerateurPort;
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
 * Contrat de bail type, prérempli avec les données du bail. Les clauses sont
 * génériques et adaptées à la nature du local (habitation, commerce, bureau) :
 * elles sont à relire et à ajuster au modèle de l'entreprise.
 */
@Component
@EnableConfigurationProperties(BailleurProperties.class)
public class ContratBailPdfGenerateur implements ContratBailGenerateurPort {

    private static final Locale FR = Locale.FRANCE;
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("d MMMM yyyy", FR);
    private static final Color ACCENT = new Color(0x1F, 0x6F, 0x5C);
    private static final Color GRIS = new Color(0x5F, 0x5E, 0x5A);
    private static final Color FOND = new Color(0xF1, 0xEF, 0xE8);

    private final BailleurProperties bailleur;

    private final Font titre = police(15, Font.BOLD, ACCENT);
    private final Font sousTitre = police(9.5f, Font.NORMAL, GRIS);
    private final Font article = police(10.5f, Font.BOLD, ACCENT);
    private final Font texte = police(9.5f, Font.NORMAL, Color.BLACK);
    private final Font gras = police(9.5f, Font.BOLD, Color.BLACK);
    private final Font petit = police(8, Font.NORMAL, GRIS);

    public ContratBailPdfGenerateur(BailleurProperties bailleur) {
        this.bailleur = bailleur;
    }

    @Override
    public byte[] generer(Bail bail) {
        ByteArrayOutputStream sortie = new ByteArrayOutputStream();
        Document document = new Document(PageSize.A4, 54, 54, 54, 60);
        try {
            PdfWriter writer = PdfWriter.getInstance(document, sortie);
            writer.setPageEvent(new PiedDePage(bail.getReference()));
            document.addTitle("Contrat de bail " + bail.getReference());
            document.addAuthor(valeur(bailleur.nom()));
            document.open();
            ecrire(document, bail);
            document.close();
        } catch (DocumentException e) {
            throw new IllegalStateException("Mise en page du contrat impossible", e);
        }
        return sortie.toByteArray();
    }

    private void ecrire(Document doc, Bail bail) throws DocumentException {
        Appartement logement = bail.getAppartement();
        Immeuble immeuble = logement.getImmeuble();
        Locataire locataire = bail.getLocataire();
        TypeLogement type = logement.getType();

        Paragraph entete = new Paragraph(titreContrat(type), titre);
        entete.setAlignment(Element.ALIGN_CENTER);
        doc.add(entete);
        Paragraph ref = new Paragraph("Bail n° " + bail.getReference(), sousTitre);
        ref.setAlignment(Element.ALIGN_CENTER);
        ref.setSpacingAfter(16);
        doc.add(ref);

        doc.add(new Paragraph("ENTRE LES SOUSSIGNÉS", article));
        doc.add(blocParties(
                "LE BAILLEUR",
                lignes(valeur(bailleur.nom()),
                        prefixe("Représenté par ", bailleur.representant()),
                        bailleur.adresse(),
                        prefixe("Tél. : ", bailleur.telephone()),
                        prefixe("E-mail : ", bailleur.email())),
                "LE PRENEUR",
                lignes(locataire.nomComplet(),
                        piece(locataire),
                        prefixe("Né(e) le ", date(locataire.getDateNaissance())),
                        prefixe("Profession : ", locataire.getProfession()),
                        locataire.getAdresse(),
                        prefixe("Tél. : ", locataire.getTelephone()),
                        prefixe("E-mail : ", locataire.getEmail()))));
        doc.add(paragraphe("Il a été convenu et arrêté ce qui suit :"));

        int n = 1;
        doc.add(titreArticle(n++, "Objet"));
        doc.add(paragraphe("Le bailleur donne en location au preneur, qui accepte, le local désigné à "
                + "l'article 2, à usage exclusif " + usage(type) + ". Le preneur ne pourra en changer la "
                + "destination sans l'accord écrit du bailleur."));

        doc.add(titreArticle(n++, "Désignation du local"));
        doc.add(tableau(List.of(
                new String[]{"Nature", libelle(type)},
                new String[]{"Référence", logement.getReference()},
                new String[]{"Immeuble", immeuble.getNom()},
                new String[]{"Adresse", joindre(", ", immeuble.getAdresse(), immeuble.getCommune(), immeuble.getVille())},
                new String[]{"Étage", etage(logement.getEtage())},
                new String[]{"Superficie", logement.getSuperficie() != null
                        ? logement.getSuperficie().stripTrailingZeros().toPlainString() + " m²" : null},
                new String[]{"Pièces", logement.getNombrePieces() != null ? logement.getNombrePieces().toString() : null})));
        doc.add(paragraphe("Le preneur déclare bien connaître le local pour l'avoir visité et le prendre "
                + "dans l'état où il se trouve au jour de l'entrée en jouissance. Un état des lieux "
                + "contradictoire est dressé à l'entrée et à la sortie."));

        doc.add(titreArticle(n++, "Durée"));
        doc.add(paragraphe(bail.getDateFin() != null
                ? "Le présent bail est consenti pour une durée déterminée, du " + date(bail.getDateDebut())
                  + " au " + date(bail.getDateFin()) + ". Il pourra être renouvelé d'un commun accord."
                : "Le présent bail prend effet le " + date(bail.getDateDebut()) + " pour une durée "
                  + "indéterminée. Chacune des parties peut y mettre fin dans les conditions de l'article "
                  + "relatif à la résiliation."));

        doc.add(titreArticle(n++, "Loyer et charges"));
        doc.add(tableau(List.of(
                new String[]{"Loyer mensuel", montant(bail.getLoyerMensuel())},
                new String[]{"Charges mensuelles", montant(bail.getCharges())},
                new String[]{"Total mensuel", montant(bail.montantMensuel())})));
        doc.add(paragraphe("Le loyer et les charges sont payables d'avance, au plus tard le "
                + bail.getJourEcheance() + " de chaque mois, en espèces contre reçu, par Mobile Money, "
                + "par virement ou par chèque. Tout paiement donne lieu à la délivrance d'une quittance. "
                + "Le loyer pourra être révisé d'un commun accord ; les nouvelles conditions s'appliqueront "
                + "aux échéances suivantes."));

        doc.add(titreArticle(n++, "Dépôt de garantie"));
        BigDecimal depot = bail.getDepotGarantie();
        doc.add(paragraphe(depot != null && depot.signum() > 0
                ? "Le preneur verse ce jour au bailleur la somme de " + montant(depot) + " à titre de dépôt "
                  + "de garantie. Non productive d'intérêts, elle lui sera restituée en fin de bail, déduction "
                  + "faite des sommes restant dues et du coût des réparations locatives constatées à l'état "
                  + "des lieux de sortie."
                : "Aucun dépôt de garantie n'est exigé du preneur."));

        doc.add(titreArticle(n++, "Obligations du preneur"));
        doc.add(liste("Le preneur s'engage à :",
                "payer le loyer et les charges aux termes convenus ;",
                "user paisiblement du local, suivant la destination prévue à l'article 1 ;",
                "entretenir le local et effectuer les réparations locatives à sa charge ;",
                "ne pas sous-louer ni céder le bail sans l'accord écrit du bailleur ;",
                "ne faire aucune transformation sans l'accord écrit du bailleur ;",
                "signaler sans délai tout sinistre ou dégradation nécessitant une intervention ;",
                "restituer le local en bon état à la fin du bail, sauf usure normale."));

        doc.add(titreArticle(n++, "Obligations du bailleur"));
        doc.add(liste("Le bailleur s'engage à :",
                "délivrer un local en bon état d'usage ;",
                "assurer au preneur la jouissance paisible du local ;",
                "effectuer les grosses réparations qui ne sont pas à la charge du preneur."));

        doc.add(titreArticle(n++, "Résiliation"));
        doc.add(paragraphe("Chaque partie peut résilier le bail en prévenant l'autre par écrit au moins un "
                + "mois à l'avance. Le loyer du mois au cours duquel la résiliation prend effet reste dû en "
                + "totalité. À défaut de paiement d'un seul terme de loyer à son échéance et un mois après une "
                + "mise en demeure restée sans effet, le bail pourra être résilié de plein droit."));

        doc.add(titreArticle(n, "Élection de domicile et litiges"));
        doc.add(paragraphe("Pour l'exécution des présentes, les parties font élection de domicile en leurs "
                + "adresses respectives. Tout litige sera, à défaut d'accord amiable, porté devant les "
                + "juridictions compétentes" + prefixe(" de ", bailleur.ville()) + "."));

        Paragraph fait = new Paragraph("Fait en deux exemplaires originaux, à "
                + valeur(bailleur.ville()) + ", le " + date(LocalDate.now()) + ".", texte);
        fait.setSpacingBefore(14);
        fait.setSpacingAfter(10);
        doc.add(fait);
        doc.add(blocSignatures());
    }

    // ── Briques de mise en page ─────────────────────────────────────────────

    private PdfPTable blocParties(String titreG, List<String> lignesG, String titreD, List<String> lignesD)
            throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setSpacingBefore(6);
        table.setSpacingAfter(8);
        table.addCell(carteParty(titreG, lignesG));
        table.addCell(carteParty(titreD, lignesD));
        return table;
    }

    private PdfPCell carteParty(String titrePartie, List<String> lignes) {
        PdfPCell cell = new PdfPCell();
        cell.setBackgroundColor(FOND);
        cell.setBorderColor(Color.WHITE);
        cell.setBorderWidth(3);
        cell.setPadding(9);
        cell.addElement(new Paragraph(titrePartie, article));
        for (int i = 0; i < lignes.size(); i++) {
            cell.addElement(new Paragraph(lignes.get(i), i == 0 ? gras : texte));
        }
        return cell;
    }

    private PdfPTable tableau(List<String[]> lignes) throws DocumentException {
        PdfPTable table = new PdfPTable(new float[]{1.2f, 2.8f});
        table.setWidthPercentage(100);
        table.setSpacingBefore(4);
        table.setSpacingAfter(6);
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

    private PdfPTable blocSignatures() throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setKeepTogether(true);
        table.addCell(caseSignature("Le bailleur"));
        table.addCell(caseSignature("Le preneur"));
        return table;
    }

    private PdfPCell caseSignature(String partie) {
        PdfPCell cell = new PdfPCell();
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setPaddingRight(12);
        cell.addElement(new Paragraph(partie, gras));
        cell.addElement(new Paragraph("Signature précédée de la mention « Lu et approuvé »", petit));
        PdfPTable cadre = new PdfPTable(1);
        cadre.setWidthPercentage(100);
        PdfPCell zone = new PdfPCell(new Phrase(" "));
        zone.setFixedHeight(70);
        zone.setBorderColor(new Color(0xB4, 0xB2, 0xA9));
        cadre.addCell(zone);
        cell.addElement(cadre);
        return cell;
    }

    private Paragraph titreArticle(int numero, String libelle) {
        Paragraph p = new Paragraph("Article " + numero + " — " + libelle, article);
        p.setSpacingBefore(10);
        p.setSpacingAfter(3);
        return p;
    }

    private Paragraph paragraphe(String contenu) {
        Paragraph p = new Paragraph(contenu, texte);
        p.setAlignment(Element.ALIGN_JUSTIFIED);
        p.setLeading(13.5f);
        p.setSpacingAfter(4);
        return p;
    }

    private Paragraph liste(String introduction, String... elements) {
        Paragraph p = new Paragraph(new Phrase(introduction, texte));
        for (String e : elements) {
            p.add(Chunk.NEWLINE);
            p.add(new Chunk("•  " + e, texte));
        }
        p.setLeading(14);
        p.setSpacingAfter(4);
        return p;
    }

    /** Numéro de page et référence du bail en pied de chaque page. */
    private final class PiedDePage extends PdfPageEventHelper {
        private final String reference;

        PiedDePage(String reference) {
            this.reference = reference;
        }

        @Override
        public void onEndPage(PdfWriter writer, Document document) {
            PdfContentByte cb = writer.getDirectContent();
            Phrase pied = new Phrase("Bail " + reference + "  ·  Page " + writer.getPageNumber()
                    + "  ·  Paraphes : ________  ________", petit);
            ColumnText.showTextAligned(cb, Element.ALIGN_CENTER, pied,
                    (document.left() + document.right()) / 2, document.bottom() - 24, 0);
        }
    }

    // ── Textes ──────────────────────────────────────────────────────────────

    private static String titreContrat(TypeLogement type) {
        return switch (type) {
            case MAGASIN -> "CONTRAT DE BAIL À USAGE COMMERCIAL";
            case BUREAU -> "CONTRAT DE BAIL À USAGE PROFESSIONNEL";
            case APPARTEMENT -> "CONTRAT DE BAIL À USAGE D'HABITATION";
        };
    }

    private static String usage(TypeLogement type) {
        return switch (type) {
            case MAGASIN -> "commercial";
            case BUREAU -> "professionnel (bureaux)";
            case APPARTEMENT -> "d'habitation";
        };
    }

    private static String libelle(TypeLogement type) {
        return switch (type) {
            case MAGASIN -> "Magasin";
            case BUREAU -> "Bureau";
            case APPARTEMENT -> "Appartement";
        };
    }

    private static String piece(Locataire l) {
        if (l.getNumeroPiece() == null || l.getNumeroPiece().isBlank()) return null;
        String type = l.getTypePiece() != null ? switch (l.getTypePiece()) {
            case CNI -> "CNI";
            case PASSEPORT -> "Passeport";
            case CARTE_CONSULAIRE -> "Carte consulaire";
            case PERMIS_CONDUIRE -> "Permis de conduire";
            case CARTE_SEJOUR -> "Carte de séjour";
            case AUTRE -> "Pièce";
        } : "Pièce";
        return type + " n° " + l.getNumeroPiece();
    }

    private static String etage(Integer etage) {
        if (etage == null) return null;
        if (etage == 0) return "Rez-de-chaussée";
        return etage == 1 ? "1er étage" : etage + "e étage";
    }

    private static String montant(BigDecimal valeur) {
        NumberFormat format = NumberFormat.getIntegerInstance(FR);
        // Espace insécable fine du format français → espace simple, mieux rendue par la police PDF.
        return format.format(valeur != null ? valeur : BigDecimal.ZERO).replace(' ', ' ').replace(' ', ' ')
                + " FCFA";
    }

    private static String date(LocalDate date) {
        return date != null ? date.format(DATE) : null;
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
