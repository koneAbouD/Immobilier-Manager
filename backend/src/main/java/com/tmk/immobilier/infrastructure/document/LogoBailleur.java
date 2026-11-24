package com.tmk.immobilier.infrastructure.document;

import com.lowagie.text.Element;
import com.lowagie.text.Image;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.util.Optional;

/** Logo de l'organisation, mis à l'échelle pour l'en-tête des documents. */
@Slf4j
@Component
@RequiredArgsConstructor
class LogoBailleur {

    private static final float LARGEUR_MAX = 150;
    private static final float HAUTEUR_MAX = 54;

    private final StockageDocumentsPort stockage;

    /** Vide sans logo, ou si le logo est illisible : le document sort quand même. */
    Optional<Image> charger(Organisation bailleur) {
        if (bailleur.getLogoCle() == null) return Optional.empty();
        try (InputStream contenu = stockage.lire(bailleur.getLogoCle())) {
            Image image = Image.getInstance(contenu.readAllBytes());
            image.scaleToFit(LARGEUR_MAX, HAUTEUR_MAX);
            image.setAlignment(Element.ALIGN_CENTER);
            image.setSpacingAfter(8);
            return Optional.of(image);
        } catch (Exception e) {
            log.warn("Logo de l'organisation {} illisible : {}", bailleur.getId(), e.getMessage());
            return Optional.empty();
        }
    }
}
