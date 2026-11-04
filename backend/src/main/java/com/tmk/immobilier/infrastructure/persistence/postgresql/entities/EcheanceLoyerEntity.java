package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.loyer.StatutEcheance;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = EcheanceLoyerEntity.TABLE_NAME)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EcheanceLoyerEntity extends AbstractAuditEntity {

    public static final String TABLE_NAME = "echeances_loyer";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "bail_id", nullable = false)
    private BailEntity bail;

    /** Premier jour du mois concerné. */
    @Column(nullable = false)
    private LocalDate periode;

    @Column(name = "date_echeance", nullable = false)
    private LocalDate dateEcheance;

    @Column(name = "montant_du", nullable = false, precision = 19, scale = 2)
    private BigDecimal montantDu;

    @Column(name = "montant_paye", nullable = false, precision = 19, scale = 2)
    private BigDecimal montantPaye;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private StatutEcheance statut;
}
