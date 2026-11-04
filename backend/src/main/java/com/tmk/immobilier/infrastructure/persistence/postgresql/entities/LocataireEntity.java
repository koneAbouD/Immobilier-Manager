package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.locataire.TypePiece;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = LocataireEntity.TABLE_NAME)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LocataireEntity extends AbstractAuditEntity {

    public static final String TABLE_NAME = "locataires";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String nom;

    @Column(nullable = false, length = 100)
    private String prenom;

    @Column(nullable = false, length = 30, unique = true)
    private String telephone;

    @Column(length = 150)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_piece", length = 30)
    private TypePiece typePiece;

    @Column(name = "numero_piece", length = 50)
    private String numeroPiece;

    @Column(length = 100)
    private String profession;

    @Column(name = "date_naissance")
    private LocalDate dateNaissance;

    private String adresse;

    @Column(name = "contact_urgence_nom", length = 150)
    private String contactUrgenceNom;

    @Column(name = "contact_urgence_telephone", length = 30)
    private String contactUrgenceTelephone;
}
