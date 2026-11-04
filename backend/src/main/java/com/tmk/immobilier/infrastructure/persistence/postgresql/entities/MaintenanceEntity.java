package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.maintenance.CategorieMaintenance;
import com.tmk.immobilier.application.domain.maintenance.PrioriteMaintenance;
import com.tmk.immobilier.application.domain.maintenance.StatutMaintenance;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = MaintenanceEntity.TABLE_NAME)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaintenanceEntity extends AbstractAuditEntity {

    public static final String TABLE_NAME = "maintenances";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "immeuble_id", nullable = false)
    private ImmeubleEntity immeuble;

    /** Logement concerné ; nul pour une intervention sur les parties communes. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "appartement_id")
    private AppartementEntity appartement;

    @Column(nullable = false, length = 150)
    private String titre;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private CategorieMaintenance categorie;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private PrioriteMaintenance priorite;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private StatutMaintenance statut;

    @Column(name = "date_signalement", nullable = false)
    private LocalDate dateSignalement;

    @Column(name = "date_prevue")
    private LocalDate datePrevue;

    @Column(name = "date_realisation")
    private LocalDate dateRealisation;

    @Column(length = 150)
    private String prestataire;

    @Column(name = "cout_estime", precision = 19, scale = 2)
    private BigDecimal coutEstime;

    @Column(name = "cout_reel", precision = 19, scale = 2)
    private BigDecimal coutReel;

    @Column(name = "motif_annulation", columnDefinition = "TEXT")
    private String motifAnnulation;

    @Column(name = "annule_par", length = 100)
    private String annulePar;

    @Column(name = "annule_le")
    private LocalDateTime annuleLe;
}
