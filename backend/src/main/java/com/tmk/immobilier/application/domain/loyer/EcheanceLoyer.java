package com.tmk.immobilier.application.domain.loyer;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.exception.RegleMetierException;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;

/**
 * Loyer d'un mois pour un bail : ce qui est dû, ce qui a été payé. Le statut
 * se déduit toujours des deux montants — jamais saisi — pour qu'une échéance
 * ne puisse pas se dire payée sans l'être.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EcheanceLoyer {

    private Long id;
    private Bail bail;
    /** Premier jour du mois concerné. */
    private LocalDate periode;
    private LocalDate dateEcheance;
    private BigDecimal montantDu;
    private BigDecimal montantPaye;
    private StatutEcheance statut;

    /** Échéance du mois donné pour un bail, à partir de ses conditions du moment. */
    public static EcheanceLoyer pour(Bail bail, YearMonth periode) {
        return EcheanceLoyer.builder()
                .bail(bail)
                .periode(periode.atDay(1))
                .dateEcheance(bail.dateEcheancePour(periode))
                .montantDu(bail.montantMensuel())
                .montantPaye(BigDecimal.ZERO)
                .statut(StatutEcheance.A_PAYER)
                .build();
    }

    public BigDecimal resteDu() {
        if (statut == StatutEcheance.ANNULEE) return BigDecimal.ZERO;
        return montantDu.subtract(montantPaye != null ? montantPaye : BigDecimal.ZERO).max(BigDecimal.ZERO);
    }

    public boolean estSoldee() {
        return statut == StatutEcheance.PAYEE;
    }

    /** Exigible, échue et pas entièrement réglée à la date donnée. */
    public boolean estEnRetard(LocalDate aujourdhui) {
        return (statut == StatutEcheance.A_PAYER || statut == StatutEcheance.PARTIEL)
                && dateEcheance.isBefore(aujourdhui);
    }

    public void enregistrerPaiement(BigDecimal montant) {
        if (statut == StatutEcheance.ANNULEE) {
            throw new RegleMetierException("ECHEANCE_ANNULEE", "Ce loyer a été annulé : il n'y a rien à encaisser.");
        }
        if (montant == null || montant.signum() <= 0) {
            throw new RegleMetierException("MONTANT_INVALIDE", "Le montant du paiement doit être strictement positif.");
        }
        if (montant.compareTo(resteDu()) > 0) {
            throw new RegleMetierException("PAIEMENT_DEPASSE_RESTE_DU",
                    "Le paiement (" + montant.toPlainString() + ") dépasse le reste dû ("
                            + resteDu().toPlainString() + ").");
        }
        this.montantPaye = montantPaye.add(montant);
        recalculerStatut();
    }

    /** Retire un paiement annulé : l'échéance redevient due d'autant. */
    public void retirerPaiement(BigDecimal montant) {
        this.montantPaye = montantPaye.subtract(montant).max(BigDecimal.ZERO);
        recalculerStatut();
    }

    /**
     * Annule un loyer qui ne sera pas dû. Refusé dès qu'un paiement y est
     * rattaché : il faudrait d'abord annuler ce paiement, sans quoi l'argent
     * encaissé n'aurait plus de contrepartie.
     */
    public void annuler() {
        if (montantPaye != null && montantPaye.signum() > 0) {
            throw new RegleMetierException("ECHEANCE_DEJA_REGLEE",
                    "Ce loyer a déjà reçu des paiements : annulez-les avant d'annuler l'échéance.");
        }
        this.statut = StatutEcheance.ANNULEE;
    }

    private void recalculerStatut() {
        if (montantPaye.signum() == 0) {
            statut = StatutEcheance.A_PAYER;
        } else if (montantPaye.compareTo(montantDu) >= 0) {
            statut = StatutEcheance.PAYEE;
        } else {
            statut = StatutEcheance.PARTIEL;
        }
    }
}
