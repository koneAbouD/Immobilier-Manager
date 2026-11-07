package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.immeuble.TypeBien;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = ImmeubleEntity.TABLE_NAME)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ImmeubleEntity extends AbstractAuditEntity {

    public static final String TABLE_NAME = "immeubles";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150, unique = true)
    private String nom;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_bien", nullable = false, length = 30)
    private TypeBien type;

    private String adresse;

    @Column(length = 100)
    private String commune;

    @Column(length = 100)
    private String ville;

    @Column(precision = 9, scale = 6)
    private BigDecimal latitude;

    @Column(precision = 9, scale = 6)
    private BigDecimal longitude;

    @Column(name = "nombre_etages")
    private Integer nombreEtages;

    @Column(name = "annee_construction")
    private Integer anneeConstruction;

    @Column(columnDefinition = "TEXT")
    private String description;
}
