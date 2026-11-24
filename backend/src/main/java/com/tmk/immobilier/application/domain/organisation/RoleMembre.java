package com.tmk.immobilier.application.domain.organisation;

/**
 * Rôle d'un membre dans une organisation, du plus au moins étendu. Chaque rôle
 * inclut les droits de ceux qui le suivent.
 */
public enum RoleMembre {
    /** Titulaire du compte : abonnement, et tout ce que peut un administrateur. */
    PROPRIETAIRE("Propriétaire"),
    /** Paramètres de l'organisation et gestion des membres. */
    ADMIN("Administrateur"),
    /** Gestion locative au quotidien : biens, baux, loyers, travaux. */
    GESTIONNAIRE("Gestionnaire"),
    /** Consultation seule (comptable, associé…). */
    LECTEUR("Lecteur");

    private final String libelle;

    RoleMembre(String libelle) {
        this.libelle = libelle;
    }

    public String getLibelle() {
        return libelle;
    }

    /** Vrai si ce rôle donne au moins les droits de [autre]. */
    public boolean inclut(RoleMembre autre) {
        return ordinal() <= autre.ordinal();
    }
}
