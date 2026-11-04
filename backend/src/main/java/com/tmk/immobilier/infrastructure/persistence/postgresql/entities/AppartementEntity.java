package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.domain.appartement.TypeLogement;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = AppartementEntity.TABLE_NAME)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppartementEntity extends AbstractAuditEntity {

    public static final String TABLE_NAME = "appartements";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "immeuble_id", nullable = false)
    private ImmeubleEntity immeuble;

    @Column(nullable = false, length = 50)
    private String reference;

    private Integer etage;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TypeLogement type;

    @Column(precision = 10, scale = 2)
    private BigDecimal superficie;

    @Column(name = "nombre_pieces")
    private Integer nombrePieces;

    @Column(name = "loyer_mensuel", nullable = false, precision = 19, scale = 2)
    private BigDecimal loyerMensuel;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal charges;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private StatutAppartement statut;

    @Column(columnDefinition = "TEXT")
    private String description;
}
