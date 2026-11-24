package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/** Compte de connexion : table globale, un compte peut servir plusieurs organisations. */
@Entity
@Table(name = "utilisateurs")
@Getter
@Setter
@NoArgsConstructor
public class UtilisateurEntity extends AbstractAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "keycloak_id", nullable = false, length = 64)
    private String keycloakId;

    /** Facultatif : un compte peut n'avoir que son numéro de téléphone. */
    @Column(length = 150)
    private String email;

    @Column(length = 100)
    private String prenom;

    @Column(length = 100)
    private String nom;

    @Column(length = 30)
    private String telephone;

    @Column(name = "derniere_connexion")
    private LocalDateTime derniereConnexion;
}
