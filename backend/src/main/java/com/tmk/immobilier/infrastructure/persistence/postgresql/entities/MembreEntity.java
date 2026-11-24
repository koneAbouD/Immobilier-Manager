package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Adhésion d'un utilisateur à une organisation : table globale, organisation explicite. */
@Entity
@Table(name = "membres")
@Getter
@Setter
@NoArgsConstructor
public class MembreEntity extends AbstractAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organisation_id", nullable = false, updatable = false)
    private OrganisationEntity organisation;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "utilisateur_id", nullable = false, updatable = false)
    private UtilisateurEntity utilisateur;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private RoleMembre role;

    @Column(nullable = false)
    private boolean actif;
}
