package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.organisation.PlanAbonnement;
import com.tmk.immobilier.application.domain.organisation.StatutAbonnement;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

/** Organisation cliente : table globale, hors cloisonnement. */
@Entity
@Table(name = "organisations")
@Getter
@Setter
@NoArgsConstructor
public class OrganisationEntity extends AbstractAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String nom;

    @Column(length = 150)
    private String representant;

    @Column(length = 150)
    private String email;

    @Column(length = 30)
    private String telephone;

    private String adresse;

    @Column(length = 100)
    private String ville;

    @Column(nullable = false, length = 2)
    private String pays;

    @Column(nullable = false, length = 3)
    private String devise;

    @Column(name = "logo_cle")
    private String logoCle;

    @Column(name = "logo_type", length = 100)
    private String logoType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private PlanAbonnement plan;

    @Enumerated(EnumType.STRING)
    @Column(name = "statut_abonnement", nullable = false, length = 30)
    private StatutAbonnement statutAbonnement;

    @Column(name = "essai_fin_le")
    private LocalDate essaiFinLe;

    @Column(name = "abonnement_fin_le")
    private LocalDate abonnementFinLe;

    @Column(nullable = false)
    private boolean historique;
}
