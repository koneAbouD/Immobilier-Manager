package com.tmk.immobilier.application.usecases.contrat;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.security.AuteurCourantPort;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.io.InputStream;
import java.util.Map;
import java.util.UUID;

/** Archive l'exemplaire signé d'un contrat ; un nouveau chargement remplace l'ancien. */
@RequiredArgsConstructor
public class DeposerContratSigneUseCase {

    /** Formats acceptés et extension du fichier rangé. */
    private static final Map<String, String> TYPES = Map.of(
            "application/pdf", "pdf",
            "image/jpeg", "jpg",
            "image/png", "png");

    private final BailRepository bailRepository;
    private final StockageDocumentsPort stockage;
    private final AuteurCourantPort auteurCourant;

    @Transactional
    public Bail execute(Long bailId, String nomFichier, String type, long taille, InputStream contenu) {
        Bail bail = bailRepository.findById(bailId).orElseThrow(() -> ResourceNotFoundException.of("Bail", bailId));
        String extension = type != null ? TYPES.get(type.toLowerCase()) : null;
        if (extension == null) {
            throw new RegleMetierException("FORMAT_CONTRAT_INVALIDE",
                    "Le contrat signé doit être un PDF ou une photo (JPEG, PNG).");
        }
        if (taille <= 0) {
            throw new RegleMetierException("CONTRAT_VIDE", "Le fichier du contrat est vide.");
        }
        String ancienneCle = bail.getContratSigneCle();
        String cle = "baux/" + bailId + "/contrat-signe-" + UUID.randomUUID() + "." + extension;
        stockage.deposer(cle, contenu, taille, type);
        String nom = nomFichier != null && !nomFichier.isBlank()
                ? nomFichier : "Contrat-signe-" + bail.getReference() + "." + extension;
        bail.enregistrerContratSigne(cle, nom, type, taille, auteurCourant.auteur());
        Bail saved = bailRepository.save(bail);
        if (ancienneCle != null) stockage.supprimer(ancienneCle);
        return saved;
    }
}
