package com.tmk.immobilier.infrastructure.persistence.postgresql.entities;

import com.tmk.immobilier.application.domain.journal.ActionJournal;
import com.tmk.immobilier.application.domain.journal.Changement;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = JournalActionEntity.TABLE_NAME)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JournalActionEntity extends AbstractTenantEntity {

    public static final String TABLE_NAME = "journal_actions";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "date_action", nullable = false)
    private LocalDateTime dateAction;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ActionJournal action;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_entite", nullable = false, length = 20)
    private TypeEntite typeEntite;

    @Column(name = "entite_id")
    private Long entiteId;

    private String libelle;

    private String contexte;

    @Column(name = "auteur_id")
    private Long auteurId;

    @Column(name = "auteur_nom")
    private String auteurNom;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(nullable = false, columnDefinition = "jsonb")
    @Builder.Default
    private List<Changement> changements = new ArrayList<>();

    @Override
    protected Object identifiant() {
        return id;
    }
}
