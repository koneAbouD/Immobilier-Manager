package com.tmk.immobilier.application.domain.immeuble;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Immeuble {

    private Long id;
    private String nom;
    private TypeBien type;
    private String adresse;
    private String commune;
    private String ville;
    /** Position relevée sur place (degrés décimaux, WGS 84) ; nulle si non renseignée. */
    private BigDecimal latitude;
    private BigDecimal longitude;
    private Integer nombreEtages;
    private Integer anneeConstruction;
    private String description;

    /**
     * Renseigné à la lecture seulement, par les use cases de consultation :
     * nombre de logements et de logements occupés. Jamais persisté — il se
     * recalcule depuis les appartements.
     */
    private OccupationImmeuble occupation;

    public boolean estTerrain() {
        return type == TypeBien.TERRAIN;
    }
}
