package com.tmk.immobilier.application.domain.appartement;

/** Nature du local loué : la taille d'un appartement se lit dans son nombre de pièces. */
public enum TypeLogement {
    APPARTEMENT,
    MAGASIN,
    BUREAU,
    ENTREPOT,
    /**
     * Le terrain lui-même, loué nu. Réservé au local créé automatiquement avec
     * un bien de type terrain : il ne se crée ni ne se choisit à la main.
     */
    TERRAIN
}
