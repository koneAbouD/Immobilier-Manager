package com.tmk.immobilier.application.common;

import com.tmk.immobilier.application.exception.RegleMetierException;

import java.util.Map;

/** Formats acceptés pour les documents chargés : PDF ou photo. */
public final class FormatsDocument {

    private static final Map<String, String> EXTENSIONS = Map.of(
            "application/pdf", "pdf",
            "image/jpeg", "jpg",
            "image/png", "png");

    private FormatsDocument() {
    }

    /**
     * Vérifie le format et la taille du fichier chargé.
     *
     * @param quoi désignation du document dans le message d'erreur (« Le contrat signé »)
     * @return l'extension du fichier rangé
     */
    public static String verifier(String type, long taille, String quoi) {
        String extension = type != null ? EXTENSIONS.get(type.toLowerCase()) : null;
        if (extension == null) {
            throw new RegleMetierException("FORMAT_DOCUMENT_INVALIDE",
                    quoi + " doit être un PDF ou une photo (JPEG, PNG).");
        }
        if (taille <= 0) {
            throw new RegleMetierException("DOCUMENT_VIDE", quoi + " : le fichier est vide.");
        }
        return extension;
    }
}
