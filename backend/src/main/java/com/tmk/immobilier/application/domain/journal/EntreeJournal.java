package com.tmk.immobilier.application.domain.journal;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Trace d'une modification ou d'une suppression : qui, quand, sur quoi, et
 * le détail des champs. Les libellés sont figés au moment de l'action : la
 * trace reste lisible après la suppression de la donnée ou le départ du membre.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EntreeJournal {

    private Long id;
    private LocalDateTime date;
    private ActionJournal action;
    private TypeEntite typeEntite;
    private Long entiteId;
    /** Nom de la donnée (« Résidence Palmiers », « A3 », « Awa Koné »…). */
    private String libelle;
    /** Rattachement utile à la lecture (bien d'un local, lieu des travaux). */
    private String contexte;
    private Long auteurId;
    private String auteurNom;
    private List<Changement> changements;
}
