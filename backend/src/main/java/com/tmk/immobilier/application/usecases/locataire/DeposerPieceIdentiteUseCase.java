package com.tmk.immobilier.application.usecases.locataire;

import com.tmk.immobilier.application.common.FormatsDocument;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import com.tmk.immobilier.application.ports.security.AuteurCourantPort;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.io.InputStream;
import java.util.UUID;

/** Archive la copie de la pièce d'identité d'un locataire ; un nouveau chargement remplace l'ancien. */
@RequiredArgsConstructor
public class DeposerPieceIdentiteUseCase {

    private final LocataireRepository locataireRepository;
    private final StockageDocumentsPort stockage;
    private final AuteurCourantPort auteurCourant;

    @Transactional
    public Locataire execute(Long locataireId, String nomFichier, String type, long taille, InputStream contenu) {
        Locataire locataire = locataireRepository.findById(locataireId)
                .orElseThrow(() -> ResourceNotFoundException.of("Locataire", locataireId));
        String extension = FormatsDocument.verifier(type, taille, "La pièce d'identité");
        String ancienneCle = locataire.getPieceCle();
        String cle = "locataires/" + locataireId + "/piece-identite-" + UUID.randomUUID() + "." + extension;
        stockage.deposer(cle, contenu, taille, type);
        String nom = nomFichier != null && !nomFichier.isBlank()
                ? nomFichier : "Piece-identite-" + locataire.getNom() + "." + extension;
        locataire.enregistrerPieceIdentite(cle, nom, type, taille, auteurCourant.auteur());
        Locataire saved = locataireRepository.save(locataire);
        if (ancienneCle != null) stockage.supprimer(ancienneCle);
        return saved;
    }
}
