package com.tmk.immobilier.application.common;

/**
 * Clés des fichiers dans le stockage objet. Tout fichier d'une organisation est
 * rangé sous son propre préfixe : une purge ou un export par organisation se
 * fait d'un seul tenant, et une clé ne se devine pas d'une organisation à
 * l'autre (UUID).
 */
public final class ClesStockage {

    private ClesStockage() {
    }

    /** @param chemin chemin relatif à l'organisation, sans « / » initial */
    public static String pour(Long organisationId, String chemin) {
        return "organisations/" + organisationId + "/" + chemin;
    }
}
