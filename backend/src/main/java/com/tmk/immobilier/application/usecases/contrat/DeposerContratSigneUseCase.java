package com.tmk.immobilier.application.usecases.contrat;

import com.tmk.immobilier.application.common.FormatsDocument;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.security.AuteurCourantPort;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.io.InputStream;
import java.util.UUID;

/** Archive l'exemplaire signé d'un contrat ; un nouveau chargement remplace l'ancien. */
@RequiredArgsConstructor
public class DeposerContratSigneUseCase {

    private final BailRepository bailRepository;
    private final StockageDocumentsPort stockage;
    private final AuteurCourantPort auteurCourant;

    @Transactional
    public Bail execute(Long bailId, String nomFichier, String type, long taille, InputStream contenu) {
        Bail bail = bailRepository.findById(bailId).orElseThrow(() -> ResourceNotFoundException.of("Bail", bailId));
        String extension = FormatsDocument.verifier(type, taille, "Le contrat signé");
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
