package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.domain.bail.UsageBail;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = BailEntity.TABLE_NAME)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BailEntity extends AbstractTenantEntity {

    public static final String TABLE_NAME = "baux";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 30)
    private String reference;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "appartement_id", nullable = false)
    private AppartementEntity appartement;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "locataire_id", nullable = false)
    private LocataireEntity locataire;

    @Enumerated(EnumType.STRING)
    @Column(name = "usage_bail", nullable = false, length = 20)
    private UsageBail usage;

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

    @Column(name = "mois_caution")
    private Integer moisCaution;

    @Column(name = "mois_avance", nullable = false)
    private Integer moisAvance;

    @Column(name = "premier_mois_facture", nullable = false)
    private LocalDate premierMoisFacture;

    @Column(name = "jour_echeance", nullable = false)
    private Integer jourEcheance;

    @Column(nullable = false)
    private Boolean externe;

    @Column(name = "gestionnaire_externe", length = 150)
    private String gestionnaireExterne;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private StatutBail statut;

    @Column(name = "date_resiliation")
    private LocalDate dateResiliation;

    @Column(name = "motif_resiliation", columnDefinition = "TEXT")
    private String motifResiliation;

    @Column(name = "resilie_par", length = 100)
    private String resiliePar;

    @Column(name = "contrat_genere_le")
    private LocalDateTime contratGenereLe;

    @Column(name = "contrat_signe_cle")
    private String contratSigneCle;

    @Column(name = "contrat_signe_nom")
    private String contratSigneNom;

    @Column(name = "contrat_signe_type", length = 100)
    private String contratSigneType;

    @Column(name = "contrat_signe_taille")
    private Long contratSigneTaille;

    @Column(name = "contrat_signe_le")
    private LocalDateTime contratSigneLe;

    @Column(name = "contrat_signe_par", length = 100)
    private String contratSignePar;

    @Override
    protected Object identifiant() {
        return id;
    }
}
