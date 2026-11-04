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

    private Long id;
    private String reference;
    private Appartement appartement;
    private Locataire locataire;
    private LocalDate dateDebut;
    /** Fin prévue du contrat ; nulle pour un bail à durée indéterminée. */
    private LocalDate dateFin;
    private BigDecimal loyerMensuel;
    private BigDecimal charges;
    /** Caution versée à l'entrée, restituable à la sortie. */
    private BigDecimal depotGarantie;
    /** Jour du mois où le loyer est exigible (1 à 28, pour exister chaque mois). */
    private Integer jourEcheance;
    private StatutBail statut;
    private LocalDate dateResiliation;
    private String motifResiliation;
    private String resiliePar;

    public void initializeDefaults() {
        if (statut == null) statut = StatutBail.ACTIF;
        if (charges == null) charges = BigDecimal.ZERO;
        if (depotGarantie == null) depotGarantie = BigDecimal.ZERO;
        if (jourEcheance == null) jourEcheance = JOUR_ECHEANCE_PAR_DEFAUT;
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
     * Vrai si le bail court sur au moins une partie du mois : un loyer est dû
     * pour ce mois. Le mois de résiliation reste dû ; les suivants non.
     */
    public boolean couvre(YearMonth periode) {
        YearMonth debut = YearMonth.from(dateDebut);
        if (periode.isBefore(debut)) return false;
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
        if (jourEcheance != null && (jourEcheance < 1 || jourEcheance > 28)) {
            throw new RegleMetierException("JOUR_ECHEANCE_INVALIDE", "Le jour d'échéance doit être compris entre 1 et 28.");
        }
    }
}
