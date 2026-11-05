package com.tmk.immobilier.application.domain.locataire;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

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

    // ── Pièce d'identité numérisée ───────────────────────────────────────
    /** Clé du fichier dans le stockage de documents ; nulle tant qu'aucune copie n'est chargée. */
    private String pieceCle;
    private String pieceNom;
    private String pieceType;
    private Long pieceTaille;
    private LocalDateTime pieceChargeeLe;
    private String pieceChargeePar;

    public String nomComplet() {
        return (prenom != null ? prenom + " " : "") + (nom != null ? nom : "");
    }

    public boolean aPieceIdentite() {
        return pieceCle != null;
    }

    /** Archive la copie de la pièce ; un nouveau chargement remplace le précédent. */
    public void enregistrerPieceIdentite(String cle, String nom, String type, long taille, String auteur) {
        this.pieceCle = cle;
        this.pieceNom = nom;
        this.pieceType = type;
        this.pieceTaille = taille;
        this.pieceChargeeLe = LocalDateTime.now();
        this.pieceChargeePar = auteur;
    }

    /** Une saisie du formulaire ne touche pas à la copie archivée : on la reprend de [existant]. */
    public void conserverPieceIdentiteDe(Locataire existant) {
        this.pieceCle = existant.pieceCle;
        this.pieceNom = existant.pieceNom;
        this.pieceType = existant.pieceType;
        this.pieceTaille = existant.pieceTaille;
        this.pieceChargeeLe = existant.pieceChargeeLe;
        this.pieceChargeePar = existant.pieceChargeePar;
    }
}
