package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = PhotoBienEntity.TABLE_NAME)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PhotoBienEntity extends AbstractAuditEntity {

    public static final String TABLE_NAME = "photos_bien";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "immeuble_id", nullable = false)
    private Long immeubleId;

    @Column(nullable = false)
    private String cle;

    private String nom;

    @Column(nullable = false, length = 100)
    private String type;

    @Column(nullable = false)
    private Long taille;
}
