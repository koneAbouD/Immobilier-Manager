package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import jakarta.persistence.*;
import lombok.*;

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

    private String adresse;

    @Column(length = 100)
    private String commune;

    @Column(length = 100)
    private String ville;

    @Column(name = "nombre_etages")
    private Integer nombreEtages;

    @Column(name = "annee_construction")
    private Integer anneeConstruction;

    @Column(columnDefinition = "TEXT")
    private String description;
}
