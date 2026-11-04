package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.bail.StatutBail;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = BailEntity.TABLE_NAME)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BailEntity extends AbstractAuditEntity {

    public static final String TABLE_NAME = "baux";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 30, unique = true)
    private String reference;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "appartement_id", nullable = false)
    private AppartementEntity appartement;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "locataire_id", nullable = false)
    private LocataireEntity locataire;

    @Column(name = "date_debut", nullable = false)
    private LocalDate dateDebut;

    @Column(name = "date_fin")
    private LocalDate dateFin;

    @Column(name = "loyer_mensuel", nullable = false, precision = 19, scale = 2)
    private BigDecimal loyerMensuel;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal charges;

    @Column(name = "depot_garantie", nullable = false, precision = 19, scale = 2)
    private BigDecimal depotGarantie;

    @Column(name = "jour_echeance", nullable = false)
    private Integer jourEcheance;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private StatutBail statut;

    @Column(name = "date_resiliation")
    private LocalDate dateResiliation;

    @Column(name = "motif_resiliation", columnDefinition = "TEXT")
    private String motifResiliation;

    @Column(name = "resilie_par", length = 100)
    private String resiliePar;
}
