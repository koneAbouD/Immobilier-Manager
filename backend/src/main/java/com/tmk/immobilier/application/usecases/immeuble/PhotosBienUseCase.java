package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.common.DocumentFichier;
import com.tmk.immobilier.application.domain.immeuble.PhotoBien;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.persistence.PhotoBienRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Consultation et suppression des photos d'un bien. */
@RequiredArgsConstructor
public class PhotosBienUseCase {

    private final PhotoBienRepository photoBienRepository;
    private final StockageDocumentsPort stockage;

    @Transactional(readOnly = true)
    public List<PhotoBien> lister(Long immeubleId) {
        return photoBienRepository.findByImmeubleId(immeubleId);
    }

    @Transactional(readOnly = true)
    public DocumentFichier fichier(Long immeubleId, Long photoId) {
        PhotoBien photo = trouver(immeubleId, photoId);
        return new DocumentFichier(photo.getNom() != null ? photo.getNom() : "photo-" + photoId,
                photo.getType(), photo.getTaille() != null ? photo.getTaille() : -1, stockage.lire(photo.getCle()));
    }

    @Transactional
    public void supprimer(Long immeubleId, Long photoId) {
        PhotoBien photo = trouver(immeubleId, photoId);
        photoBienRepository.deleteById(photoId);
        stockage.supprimer(photo.getCle());
    }

    private PhotoBien trouver(Long immeubleId, Long photoId) {
        return photoBienRepository.findById(photoId)
                .filter(p -> p.getImmeubleId().equals(immeubleId))
                .orElseThrow(() -> ResourceNotFoundException.of("Photo", photoId));
    }
}
