package com.tmk.immobilier.application.domain.maintenance;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.exception.RegleMetierException;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Intervention sur un immeuble — ses parties communes, ou l'un de ses
 * logements quand {@link #appartement} est renseigné.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Maintenance {

    private Long id;
    private Immeuble immeuble;
    private Appartement appartement;
    private String titre;
    private String description;
    private CategorieMaintenance categorie;
    private PrioriteMaintenance priorite;
    private StatutMaintenance statut;
    private LocalDate dateSignalement;
    private LocalDate datePrevue;
    private LocalDate dateRealisation;
    /** Artisan ou entreprise chargé(e) de l'intervention. */
    private String prestataire;
    private BigDecimal coutEstime;
    private BigDecimal coutReel;

    /**
     * Pourquoi l'intervention a été annulée, qui l'a décidé et quand : une
     * annulation sans motif ne se distingue pas d'un oubli.
     */
    private String motifAnnulation;
    private String annulePar;
    private LocalDateTime annuleLe;

    public void initializeDefaults() {
        if (priorite == null) priorite = PrioriteMaintenance.NORMALE;
        if (dateSignalement == null) dateSignalement = LocalDate.now();
        if (statut == null) statut = datePrevue != null ? StatutMaintenance.PLANIFIEE : StatutMaintenance.SIGNALEE;
    }

    public void demarrer() {
        exigerOuverte();
        if (statut == StatutMaintenance.EN_COURS) {
            throw new RegleMetierException("MAINTENANCE_DEJA_EN_COURS", "Cette intervention est déjà en cours.");
        }
        this.statut = StatutMaintenance.EN_COURS;
    }

    public void terminer(BigDecimal coutEffectif, LocalDate dateEffective) {
        exigerOuverte();
        this.statut = StatutMaintenance.TERMINEE;
        this.dateRealisation = dateEffective != null ? dateEffective : LocalDate.now();
        if (coutEffectif != null) this.coutReel = coutEffectif;
    }

    public void annuler(String motif, String auteur) {
        exigerOuverte();
        this.statut = StatutMaintenance.ANNULEE;
        this.motifAnnulation = motif;
        this.annulePar = auteur;
        this.annuleLe = LocalDateTime.now();
    }

    /** Une date fixée sur une intervention seulement signalée la programme. */
    public void planifierSiDate() {
        if (statut == StatutMaintenance.SIGNALEE && datePrevue != null) {
            statut = StatutMaintenance.PLANIFIEE;
        }
    }

    private void exigerOuverte() {
        if (statut == null || !statut.estOuverte()) {
            throw new RegleMetierException("MAINTENANCE_CLOSE",
                    "Cette intervention est " + (statut == StatutMaintenance.TERMINEE ? "terminée" : "annulée")
                            + " : elle ne peut plus changer d'état.");
        }
    }
}
