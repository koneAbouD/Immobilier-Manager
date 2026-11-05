package com.tmk.immobilier.application.usecases.contrat;

import java.io.InputStream;

/** Fichier de contrat renvoyé au client : nom proposé, type MIME, contenu. */
public record DocumentContrat(String nomFichier, String type, long taille, InputStream contenu) {
}
