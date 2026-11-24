package com.tmk.immobilier.application.ports.document;

import java.io.InputStream;

/**
 * Stockage des fichiers chargés par les utilisateurs (contrats signés, pièces,
 * photos, logos). Les clés sont construites par les use cases avec
 * {@link com.tmk.immobilier.application.common.ClesStockage}.
 */
public interface StockageDocumentsPort {

    void deposer(String cle, InputStream contenu, long taille, String type);

    InputStream lire(String cle);

    /** Sans effet si la clé n'existe pas. */
    void supprimer(String cle);
}
