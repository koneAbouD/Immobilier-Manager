package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.domain.immeuble.PhotoBien;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import com.tmk.immobilier.application.ports.persistence.PhotoBienRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.io.InputStream;
import java.util.Map;
import java.util.UUID;

/** Ajoute une photo (JPEG, PNG) à un bien, dans la limite de {@value #PHOTOS_MAX} photos. */
@RequiredArgsConstructor
public class AjouterPhotoBienUseCase {

    public static final int PHOTOS_MAX = 20;

    private static final Map<String, String> EXTENSIONS = Map.of(
            "image/jpeg", "jpg",
            "image/png", "png");

    private final ImmeubleRepository immeubleRepository;
    private final PhotoBienRepository photoBienRepository;
    private final StockageDocumentsPort stockage;

    @Transactional
    public PhotoBien execute(Long immeubleId, String nomFichier, String type, long taille, InputStream contenu) {
        immeubleRepository.findById(immeubleId).orElseThrow(() -> ResourceNotFoundException.of("Bien", immeubleId));
        String extension = type != null ? EXTENSIONS.get(type.toLowerCase()) : null;
        if (extension == null) {
            throw new RegleMetierException("FORMAT_PHOTO_INVALIDE", "La photo doit être une image JPEG ou PNG.");
        }
        if (taille <= 0) {
            throw new RegleMetierException("PHOTO_VIDE", "La photo est vide.");
        }
        if (photoBienRepository.countByImmeubleId(immeubleId) >= PHOTOS_MAX) {
            throw new RegleMetierException("PHOTOS_MAX_ATTEINT",
                    "Un bien compte au plus " + PHOTOS_MAX + " photos : supprimez-en une pour en ajouter.");
        }
        String cle = "biens/" + immeubleId + "/photo-" + UUID.randomUUID() + "." + extension;
        stockage.deposer(cle, contenu, taille, type);
        return photoBienRepository.save(PhotoBien.builder()
                .immeubleId(immeubleId)
                .cle(cle)
                .nom(nomFichier)
                .type(type)
                .taille(taille)
                .build());
    }
}
