package com.tmk.immobilier.application.domain.appartement;

import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.exception.RegleMetierException;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Appartement {

    private Long id;
    private Immeuble immeuble;
    /** Référence lisible du logement dans son immeuble (ex. « A12 », « RDC-2 »). */
    private String reference;
    private Integer etage;
    private TypeLogement type;
    private BigDecimal superficie;
    private Integer nombrePieces;
    /** Loyer proposé ; recopié dans le bail à sa signature, qui fait ensuite foi. */
    private BigDecimal loyerMensuel;
    private BigDecimal charges;
    private StatutAppartement statut;
    private String description;

    public void initializeDefaults() {
        if (statut == null) statut = StatutAppartement.LIBRE;
        if (charges == null) charges = BigDecimal.ZERO;
    }

    public boolean estLibre() {
        return statut == StatutAppartement.LIBRE;
    }

    public boolean estOccupe() {
        return statut == StatutAppartement.OCCUPE;
    }

    /** Un bail vient d'être signé sur ce logement. */
    public void occuper() {
        if (!estLibre()) {
            throw new RegleMetierException("APPARTEMENT_NON_DISPONIBLE",
                    "Le logement " + reference + " n'est pas disponible à la location (statut : " + statut + ").");
        }
        this.statut = StatutAppartement.OCCUPE;
    }

    /** Le bail qui le couvrait a pris fin. */
    public void liberer() {
        this.statut = StatutAppartement.LIBRE;
    }

    /**
     * Changement de statut demandé par une saisie. OCCUPE ne se pose ni ne se
     * lève à la main : il reflète l'existence d'un bail actif, et le casser
     * ferait mentir la liste des logements disponibles.
     */
    public void changerStatutManuellement(StatutAppartement nouveau) {
        if (nouveau == null || nouveau == statut) return;
        if (nouveau == StatutAppartement.OCCUPE || estOccupe()) {
            throw new RegleMetierException("STATUT_GERE_PAR_BAIL",
                    "Le statut « occupé » est géré par les baux : signez ou résiliez un bail pour le modifier.");
        }
        this.statut = nouveau;
    }

    public BigDecimal montantMensuel() {
        return loyerMensuel.add(charges != null ? charges : BigDecimal.ZERO);
    }
}
