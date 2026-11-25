package com.tmk.immobilier.application.domain.bail;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.RegleMetierException;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;

/**
 * Contrat de location : lie un locataire à un logement et fixe ce qu'il doit
 * chaque mois. C'est lui, et non l'appartement, qui porte le loyer exigible —
 * le loyer affiché du logement peut évoluer sans réécrire les baux en cours.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Bail {

    public static final int JOUR_ECHEANCE_PAR_DEFAUT = 5;
    public static final int MOIS_CAUTION_MAX = 24;
    /** Usage courant : deux mois de loyer en caution. */
    public static final int MOIS_CAUTION_PAR_DEFAUT = 2;
    public static final int MOIS_AVANCE_MAX = 24;
    /** Usage courant : deux mois de loyer réglés d'avance à la signature. */
    public static final int MOIS_AVANCE_PAR_DEFAUT = 2;
    /** Délai, après l'enregistrement du bail, pendant lequel il peut passer externe ou interne. */
    public static final int DELAI_CHANGEMENT_RECOUVREMENT_JOURS = 45;

    private Long id;
    private String reference;
    private Appartement appartement;
    private Locataire locataire;
    /** Régime du bail : habitation ou professionnel ; il fixe le modèle de contrat. */
    private UsageBail usage;
    private LocalDate dateDebut;
    /** Fin prévue du contrat ; nulle pour un bail à durée indéterminée. */
    private LocalDate dateFin;
    private BigDecimal loyerMensuel;
    private BigDecimal charges;
    /** Caution versée à l'entrée, restituable à la sortie. */
    private BigDecimal depotGarantie;
    /** Nombre de mois de loyer exigés en caution ; le dépôt de garantie en découle. */
    private Integer moisCaution;
    /**
     * Nombre de mois de loyer réglés d'avance à la signature. Contrairement à
     * la caution, ils ne sont pas restitués : ils paient les premiers mois du
     * bail, qui ne sont donc pas facturés.
     */
    private Integer moisAvance;
    /**
     * Premier jour du premier mois pour lequel un loyer est émis. Calculé à la
     * création (voir {@link #calculerPremierMoisFacture}), puis conservé :
     * modifiable par un gestionnaire pour un cas particulier.
     */
    private LocalDate premierMoisFacture;
    /** Date d'enregistrement du bail dans l'application ; lecture seule. */
    private LocalDate creeLe;
    /** Jour du mois où le loyer est exigible (1 à 28, pour exister chaque mois). */
    private Integer jourEcheance;
    /**
     * Bail externe : le recouvrement des loyers est assuré par une autre entité
     * (agence, mandataire…). L'application n'en émet aucun loyer.
     */
    private Boolean externe;
    /** Entité chargée du recouvrement d'un bail externe ; facultatif. */
    private String gestionnaireExterne;
    private StatutBail statut;
    private LocalDate dateResiliation;
    private String motifResiliation;
    private String resiliePar;

    // ── Contrat ──────────────────────────────────────────────────────────
    /** Dernière génération du contrat PDF à faire signer. */
    private LocalDateTime contratGenereLe;
    /** Clé de l'exemplaire signé dans le stockage de documents ; nulle tant qu'il n'est pas chargé. */
    private String contratSigneCle;
    private String contratSigneNom;
    private String contratSigneType;
    private Long contratSigneTaille;
    private LocalDateTime contratSigneLe;
    private String contratSignePar;

    public void initializeDefaults() {
        if (statut == null) statut = StatutBail.ACTIF;
        if (usage == null) usage = UsageBail.parDefautPour(appartement != null ? appartement.getType() : null);
        if (charges == null) charges = BigDecimal.ZERO;
        if (depotGarantie == null) depotGarantie = BigDecimal.ZERO;
        if (jourEcheance == null) jourEcheance = JOUR_ECHEANCE_PAR_DEFAUT;
        if (moisAvance == null) moisAvance = MOIS_AVANCE_PAR_DEFAUT;
        if (externe == null) externe = false;
        if (!estExterne()) gestionnaireExterne = null;
    }

    /**
     * Change le mode de recouvrement. Le basculement externe/interne n'est
     * permis que dans les {@value #DELAI_CHANGEMENT_RECOUVREMENT_JOURS} jours
     * qui suivent l'enregistrement du bail ; le nom de l'entité se corrige à
     * tout moment.
     *
     * @param nouvelExterne nul : recouvrement inchangé, entité comprise
     * @return vrai si le bail vient de passer externe
     */
    public boolean changerRecouvrement(Boolean nouvelExterne, String gestionnaire, LocalDate aujourdhui) {
        if (nouvelExterne == null) return false;
        boolean cible = nouvelExterne;
        boolean devientExterne = cible && !estExterne();
        if (cible != estExterne()) {
            LocalDate creation = creeLe != null ? creeLe : aujourdhui;
            LocalDate limite = creation.plusDays(DELAI_CHANGEMENT_RECOUVREMENT_JOURS);
            if (aujourdhui.isAfter(limite)) {
                throw new RegleMetierException("DELAI_RECOUVREMENT_DEPASSE",
                        "Le recouvrement d'un bail ne change que dans les " + DELAI_CHANGEMENT_RECOUVREMENT_JOURS
                                + " jours suivant sa création (jusqu'au " + limite + ").");
            }
            externe = cible;
        }
        gestionnaireExterne = cible && gestionnaire != null && !gestionnaire.isBlank() ? gestionnaire.trim() : null;
        return devientExterne;
    }

    /** Vrai si les loyers sont recouvrés par une autre entité : aucun loyer n'est émis. */
    public boolean estExterne() {
        return Boolean.TRUE.equals(externe);
    }

    /**
     * Premier mois facturé = le plus tardif de :
     * <ul>
     *   <li>le mois qui suit l'enregistrement du bail — rien n'est facturé
     *       rétroactivement, le passé d'un bail existant est réputé réglé ;</li>
     *   <li>le mois de début + les mois d'avance — ces mois sont déjà payés.</li>
     * </ul>
     */
    public static YearMonth calculerPremierMoisFacture(LocalDate dateDebut, Integer moisAvance, LocalDate creation) {
        YearMonth apresCreation = YearMonth.from(creation).plusMonths(1);
        YearMonth apresAvance = YearMonth.from(dateDebut).plusMonths(moisAvance != null ? moisAvance : 0);
        return apresCreation.isAfter(apresAvance) ? apresCreation : apresAvance;
    }

    /** Recalcule le premier mois facturé, la création valant à défaut aujourd'hui. */
    public void recalculerPremierMoisFacture() {
        LocalDate creation = creeLe != null ? creeLe : LocalDate.now();
        premierMoisFacture = calculerPremierMoisFacture(dateDebut, moisAvance, creation).atDay(1);
    }

    /** Ramène une date saisie au premier jour de son mois. */
    public void definirPremierMoisFacture(LocalDate mois) {
        premierMoisFacture = mois != null ? YearMonth.from(mois).atDay(1) : null;
    }

    /** Premier mois facturé ; à défaut, le mois de début. */
    public YearMonth premierMois() {
        return premierMoisFacture != null ? YearMonth.from(premierMoisFacture) : YearMonth.from(dateDebut);
    }

    /** Montant réglé d'avance à la signature : mois d'avance × loyer et charges. */
    public BigDecimal montantAvance() {
        int mois = moisAvance != null ? moisAvance : 0;
        return montantMensuel().multiply(BigDecimal.valueOf(mois));
    }

    /**
     * Dépôt de garantie = mois de caution × loyer mensuel. Sans nombre de mois,
     * le montant saisi est conservé tel quel.
     */
    public void appliquerCaution() {
        if (moisCaution != null && loyerMensuel != null) {
            depotGarantie = loyerMensuel.multiply(BigDecimal.valueOf(moisCaution));
        }
    }

    public boolean estProfessionnel() {
        return usage == UsageBail.PROFESSIONNEL;
    }

    public boolean estActif() {
        return statut == StatutBail.ACTIF;
    }

    /** Ce que le locataire doit chaque mois : loyer et charges. */
    public BigDecimal montantMensuel() {
        return loyerMensuel.add(charges != null ? charges : BigDecimal.ZERO);
    }

    /** Date d'exigibilité du loyer du mois donné. */
    public LocalDate dateEcheancePour(YearMonth periode) {
        return periode.atDay(jourEcheance != null ? jourEcheance : JOUR_ECHEANCE_PAR_DEFAUT);
    }

    /**
     * Vrai si un loyer est dû pour ce mois : à partir du premier mois facturé,
     * jusqu'au mois de résiliation (ou de fin) inclus. Jamais pour un bail externe.
     */
    public boolean couvre(YearMonth periode) {
        if (estExterne()) return false;
        if (periode.isBefore(premierMois())) return false;
        LocalDate fin = dateResiliation != null ? dateResiliation : dateFin;
        return fin == null || !periode.isAfter(YearMonth.from(fin));
    }

    public void resilier(LocalDate date, String motif, String auteur) {
        if (!estActif()) {
            throw new RegleMetierException("BAIL_NON_ACTIF", "Ce bail est déjà résilié.");
        }
        LocalDate effet = date != null ? date : LocalDate.now();
        if (effet.isBefore(dateDebut)) {
            throw new RegleMetierException("DATE_RESILIATION_INVALIDE",
                    "La résiliation ne peut pas précéder le début du bail (" + dateDebut + ").");
        }
        this.statut = StatutBail.RESILIE;
        this.dateResiliation = effet;
        this.motifResiliation = motif;
        this.resiliePar = auteur;
    }

    /** Valide la cohérence des dates et montants saisis. */
    public void valider() {
        if (dateDebut == null) {
            throw new RegleMetierException("DATE_DEBUT_OBLIGATOIRE", "La date de début du bail est obligatoire.");
        }
        if (dateFin != null && !dateFin.isAfter(dateDebut)) {
            throw new RegleMetierException("DATES_BAIL_INVALIDES", "La date de fin doit être postérieure à la date de début.");
        }
        if (loyerMensuel == null || loyerMensuel.signum() <= 0) {
            throw new RegleMetierException("LOYER_INVALIDE", "Le loyer mensuel doit être strictement positif.");
        }
        if (moisCaution != null && (moisCaution < 0 || moisCaution > MOIS_CAUTION_MAX)) {
            throw new RegleMetierException("MOIS_CAUTION_INVALIDE",
                    "Le nombre de mois de caution doit être compris entre 0 et " + MOIS_CAUTION_MAX + ".");
        }
        if (moisAvance != null && (moisAvance < 0 || moisAvance > MOIS_AVANCE_MAX)) {
            throw new RegleMetierException("MOIS_AVANCE_INVALIDE",
                    "Le nombre de mois d'avance doit être compris entre 0 et " + MOIS_AVANCE_MAX + ".");
        }
        if (premierMoisFacture != null && YearMonth.from(premierMoisFacture).isBefore(YearMonth.from(dateDebut))) {
            throw new RegleMetierException("PREMIER_MOIS_INVALIDE",
                    "Le premier loyer facturé ne peut pas précéder le mois de début du bail.");
        }
        if (jourEcheance != null && (jourEcheance < 1 || jourEcheance > 28)) {
            throw new RegleMetierException("JOUR_ECHEANCE_INVALIDE", "Le jour d'échéance doit être compris entre 1 et 28.");
        }
    }

    public StatutContrat statutContrat() {
        if (contratSigneCle != null) return StatutContrat.SIGNE;
        return contratGenereLe != null ? StatutContrat.A_SIGNER : StatutContrat.A_GENERER;
    }

    public void marquerContratGenere() {
        this.contratGenereLe = LocalDateTime.now();
    }

    /** Archive l'exemplaire signé ; un nouveau chargement remplace le précédent. */
    public void enregistrerContratSigne(String cle, String nom, String type, long taille, String auteur) {
        this.contratSigneCle = cle;
        this.contratSigneNom = nom;
        this.contratSigneType = type;
        this.contratSigneTaille = taille;
        this.contratSigneLe = LocalDateTime.now();
        this.contratSignePar = auteur;
    }
}
