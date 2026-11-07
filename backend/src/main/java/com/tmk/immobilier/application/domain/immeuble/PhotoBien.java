package com.tmk.immobilier.application.domain.immeuble;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** Photo d'un bien ; le fichier est dans le stockage de documents, sous [cle]. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PhotoBien {

    private Long id;
    private Long immeubleId;
    private String cle;
    private String nom;
    private String type;
    private Long taille;
    /** Renseignés par l'auditing à l'enregistrement. */
    private LocalDateTime ajouteeLe;
    private String ajouteePar;
}
