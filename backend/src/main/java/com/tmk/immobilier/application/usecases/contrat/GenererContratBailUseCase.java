package com.tmk.immobilier.application.usecases.contrat;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.ContratBailGenerateurPort;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayInputStream;

/**
 * Produit le contrat PDF d'un bail à partir de ses conditions actuelles. Il
 * n'est pas conservé : on le régénère à la demande, toujours à jour.
 */
@RequiredArgsConstructor
public class GenererContratBailUseCase {

    private final BailRepository bailRepository;
    private final ContratBailGenerateurPort generateur;

    @Transactional
    public DocumentContrat execute(Long bailId) {
        Bail bail = bailRepository.findById(bailId).orElseThrow(() -> ResourceNotFoundException.of("Bail", bailId));
        byte[] pdf = generateur.generer(bail);
        bail.marquerContratGenere();
        bailRepository.save(bail);
        return new DocumentContrat("Contrat-" + bail.getReference() + ".pdf", "application/pdf", pdf.length,
                new ByteArrayInputStream(pdf));
    }
}
