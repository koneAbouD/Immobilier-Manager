package com.tmk.immobilier.application.domain.loyer;

import com.tmk.immobilier.application.exception.RegleMetierException;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Encaissement d'un loyer. Un paiement ne se supprime jamais : il s'annule,
 * avec un motif et un auteur, pour que la trace de l'argent reçu survive à
 * l'erreur de saisie.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaiementLoyer {

    private Long id;
    private EcheanceLoyer echeance;
    private BigDecimal montant;
    private LocalDate datePaiement;
    private ModePaiement modePaiement;
    /** Référence externe : n° de transaction Mobile Money, de chèque, de virement. */
    private String reference;
    private String commentaire;
    private boolean annule;
    private String motifAnnulation;
    private String annulePar;
    private LocalDateTime annuleLe;
    /** Agent ayant saisi l'encaissement (piste d'audit, lecture seule). */
    private String encaissePar;

    public void annuler(String motif, String auteur) {
        if (annule) {
            throw new RegleMetierException("PAIEMENT_DEJA_ANNULE", "Ce paiement est déjà annulé.");
        }
        this.annule = true;
        this.motifAnnulation = motif;
        this.annulePar = auteur;
        this.annuleLe = LocalDateTime.now();
    }
}
