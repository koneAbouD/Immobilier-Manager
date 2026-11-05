package com.tmk.immobilier.application.common;

import java.io.InputStream;

/** Fichier renvoyé au client (contrat, pièce d'identité…) : nom proposé, type MIME, contenu. */
public record DocumentFichier(String nomFichier, String type, long taille, InputStream contenu) {
}
