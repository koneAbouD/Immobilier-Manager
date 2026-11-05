package com.tmk.immobilier.interfaces.rest.common;

import com.tmk.immobilier.application.common.DocumentFichier;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

import java.nio.charset.StandardCharsets;

/** Réponse HTTP d'un fichier, affiché par le client plutôt que téléchargé. */
public final class ReponsesFichier {

    private ReponsesFichier() {
    }

    public static ResponseEntity<InputStreamResource> fichier(DocumentFichier document) {
        ResponseEntity.BodyBuilder reponse = ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(document.type()))
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.inline()
                        .filename(document.nomFichier(), StandardCharsets.UTF_8).build().toString());
        if (document.taille() >= 0) reponse.contentLength(document.taille());
        return reponse.body(new InputStreamResource(document.contenu()));
    }
}
