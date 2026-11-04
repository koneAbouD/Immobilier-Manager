package com.tmk.immobilier.application.domain.locataire;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Locataire {

    private Long id;
    private String nom;
    private String prenom;
    private String telephone;
    private String email;
    private TypePiece typePiece;
    private String numeroPiece;
    private String profession;
    private LocalDate dateNaissance;
    private String adresse;
    /** Personne à prévenir en cas d'urgence ou d'impayé prolongé. */
    private String contactUrgenceNom;
    private String contactUrgenceTelephone;

    public String nomComplet() {
        return (prenom != null ? prenom + " " : "") + (nom != null ? nom : "");
    }
}
