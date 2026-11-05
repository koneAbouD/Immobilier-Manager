package com.tmk.immobilier.application.usecases.contrat;

import com.tmk.immobilier.application.common.DocumentFichier;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class GetContratSigneUseCase {

    private final BailRepository bailRepository;
    private final StockageDocumentsPort stockage;

    @Transactional(readOnly = true)
    public DocumentFichier execute(Long bailId) {
        Bail bail = bailRepository.findById(bailId).orElseThrow(() -> ResourceNotFoundException.of("Bail", bailId));
        if (bail.getContratSigneCle() == null) {
            throw new ResourceNotFoundException("Aucun contrat signé n'a été chargé pour le bail " + bail.getReference() + ".");
        }
        return new DocumentFichier(bail.getContratSigneNom(), bail.getContratSigneType(),
                bail.getContratSigneTaille() != null ? bail.getContratSigneTaille() : -1,
                stockage.lire(bail.getContratSigneCle()));
    }
}
