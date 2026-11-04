package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.loyer.ModePaiement;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = PaiementLoyerEntity.TABLE_NAME)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaiementLoyerEntity extends AbstractAuditEntity {

    public static final String TABLE_NAME = "paiements_loyer";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "echeance_id", nullable = false)
    private EcheanceLoyerEntity echeance;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal montant;

    @Column(name = "date_paiement", nullable = false)
    private LocalDate datePaiement;

    @Enumerated(EnumType.STRING)
    @Column(name = "mode_paiement", nullable = false, length = 30)
    private ModePaiement modePaiement;

    @Column(length = 100)
    private String reference;

    @Column(columnDefinition = "TEXT")
    private String commentaire;

    @Column(nullable = false)
    private boolean annule;

    @Column(name = "motif_annulation", columnDefinition = "TEXT")
    private String motifAnnulation;

    @Column(name = "annule_par", length = 100)
    private String annulePar;

    @Column(name = "annule_le")
    private LocalDateTime annuleLe;
}
