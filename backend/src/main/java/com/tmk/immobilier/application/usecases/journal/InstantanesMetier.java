package com.tmk.immobilier.application.usecases.journal;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.journal.Instantane;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.domain.maintenance.Maintenance;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Map;

/**
 * Instantanés lisibles des données tracées : libellés de la fiche, montants,
 * dates et énumérations en clair, comme l'utilisateur les a saisis.
 */
public final class InstantanesMetier {

    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    /** Libellés des énumérations, alignés sur ceux de l'application mobile. */
    private static final Map<String, String> LIBELLES = Map.ofEntries(
            Map.entry("IMMEUBLE", "Immeuble"), Map.entry("COUR_BASSE", "Cour basse"), Map.entry("TERRAIN", "Terrain"),
            Map.entry("APPARTEMENT", "Appartement"), Map.entry("MAGASIN", "Magasin"), Map.entry("BUREAU", "Bureau"),
            Map.entry("ENTREPOT", "Entrepôt"), Map.entry("LIBRE", "Libre"), Map.entry("OCCUPE", "Occupé"),
            Map.entry("EN_TRAVAUX", "En travaux"),
            Map.entry("CNI", "Carte nationale d'identité"), Map.entry("PASSEPORT", "Passeport"),
            Map.entry("CARTE_CONSULAIRE", "Carte consulaire"), Map.entry("PERMIS_CONDUIRE", "Permis de conduire"),
            Map.entry("CARTE_SEJOUR", "Carte de séjour"), Map.entry("AUTRE", "Autre"),
            Map.entry("PLOMBERIE", "Plomberie"), Map.entry("ELECTRICITE", "Électricité"),
            Map.entry("PEINTURE", "Peinture"), Map.entry("MENUISERIE", "Menuiserie"),
            Map.entry("CLIMATISATION", "Climatisation"), Map.entry("SERRURERIE", "Serrurerie"),
            Map.entry("MACONNERIE", "Maçonnerie"), Map.entry("NETTOYAGE", "Nettoyage"),
            Map.entry("BASSE", "Basse"), Map.entry("NORMALE", "Normale"), Map.entry("HAUTE", "Haute"),
            Map.entry("URGENTE", "Urgente"),
            Map.entry("SIGNALEE", "Signalée"), Map.entry("PLANIFIEE", "Planifiée"), Map.entry("EN_COURS", "En cours"),
            Map.entry("TERMINEE", "Terminée"), Map.entry("ANNULEE", "Annulée"));

    private InstantanesMetier() {
    }

    public static Instantane de(Immeuble i) {
        return new Instantane()
                .avec("Nom", i.getNom())
                .avec("Type", libelle(i.getType()))
                .avec("Adresse", i.getAdresse())
                .avec("Commune", i.getCommune())
                .avec("Ville", i.getVille())
                .avec("Position GPS", position(i.getLatitude(), i.getLongitude()))
                .avec("Étages", i.getNombreEtages())
                .avec("Année de construction", i.getAnneeConstruction())
                .avec("Description", i.getDescription());
    }

    public static Instantane de(Appartement a) {
        return new Instantane()
                .avec("Référence", a.getReference())
                .avec("Type", libelle(a.getType()))
                .avec("Étage", a.getEtage())
                .avec("Superficie", a.getSuperficie() == null ? null : nombre(a.getSuperficie()) + " m²")
                .avec("Pièces", a.getNombrePieces())
                .avec("Loyer mensuel", montant(a.getLoyerMensuel()))
                .avec("Charges", montant(a.getCharges()))
                .avec("Statut", libelle(a.getStatut()))
                .avec("Description", a.getDescription());
    }

    public static Instantane de(Locataire l) {
        return new Instantane()
                .avec("Prénom", l.getPrenom())
                .avec("Nom", l.getNom())
                .avec("Téléphone", l.getTelephone())
                .avec("E-mail", l.getEmail())
                .avec("Pièce d'identité", libelle(l.getTypePiece()))
                .avec("Numéro de pièce", l.getNumeroPiece())
                .avec("Profession", l.getProfession())
                .avec("Date de naissance", date(l.getDateNaissance()))
                .avec("Adresse", l.getAdresse())
                .avec("Contact d'urgence", l.getContactUrgenceNom())
                .avec("Téléphone d'urgence", l.getContactUrgenceTelephone());
    }

    public static Instantane de(Maintenance m) {
        return new Instantane()
                .avec("Titre", m.getTitre())
                .avec("Lieu", lieu(m))
                .avec("Catégorie", libelle(m.getCategorie()))
                .avec("Priorité", libelle(m.getPriorite()))
                .avec("Statut", libelle(m.getStatut()))
                .avec("Signalée le", date(m.getDateSignalement()))
                .avec("Prévue le", date(m.getDatePrevue()))
                .avec("Réalisée le", date(m.getDateRealisation()))
                .avec("Prestataire", m.getPrestataire())
                .avec("Coût estimé", montant(m.getCoutEstime()))
                .avec("Coût réel", montant(m.getCoutReel()))
                .avec("Motif d'annulation", m.getMotifAnnulation())
                .avec("Description", m.getDescription());
    }

    /** Bien d'un local, pour situer l'entrée du journal. */
    public static String contexte(Appartement a) {
        return a.getImmeuble() == null ? null : a.getImmeuble().getNom();
    }

    /** Lieu des travaux : « Bien · Local », ou le bien seul. */
    public static String lieu(Maintenance m) {
        String bien = m.getImmeuble() == null ? null : m.getImmeuble().getNom();
        String local = m.getAppartement() == null ? null : m.getAppartement().getReference();
        if (bien == null) return local;
        return local == null ? bien : bien + " · " + local;
    }

    static String libelle(Enum<?> valeur) {
        if (valeur == null) return null;
        String code = valeur.name();
        String libelle = LIBELLES.get(code);
        if (libelle != null) return libelle;
        String texte = code.replace('_', ' ').toLowerCase(Locale.FRENCH);
        return Character.toUpperCase(texte.charAt(0)) + texte.substring(1);
    }

    static String montant(BigDecimal valeur) {
        return valeur == null ? null : nombre(valeur.setScale(0, RoundingMode.HALF_UP)) + " FCFA";
    }

    private static String nombre(BigDecimal valeur) {
        DecimalFormatSymbols symboles = new DecimalFormatSymbols(Locale.FRENCH);
        symboles.setGroupingSeparator(' ');
        symboles.setDecimalSeparator(',');
        return new DecimalFormat("#,##0.##", symboles).format(valeur);
    }

    private static String date(LocalDate date) {
        return date == null ? null : DATE.format(date);
    }

    private static String position(BigDecimal latitude, BigDecimal longitude) {
        if (latitude == null || longitude == null) return null;
        return latitude.stripTrailingZeros().toPlainString() + ", " + longitude.stripTrailingZeros().toPlainString();
    }
}
