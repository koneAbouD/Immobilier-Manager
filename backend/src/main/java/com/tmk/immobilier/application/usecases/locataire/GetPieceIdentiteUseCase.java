package com.tmk.immobilier.application.usecases.locataire;

import com.tmk.immobilier.application.common.DocumentFichier;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class GetPieceIdentiteUseCase {

    private final LocataireRepository locataireRepository;
    private final StockageDocumentsPort stockage;

    @Transactional(readOnly = true)
    public DocumentFichier execute(Long locataireId) {
        Locataire locataire = locataireRepository.findById(locataireId)
                .orElseThrow(() -> ResourceNotFoundException.of("Locataire", locataireId));
        if (!locataire.aPieceIdentite()) {
            throw new ResourceNotFoundException(
                    "Aucune pièce d'identité n'a été chargée pour " + locataire.nomComplet() + ".");
        }
        return new DocumentFichier(locataire.getPieceNom(), locataire.getPieceType(),
                locataire.getPieceTaille() != null ? locataire.getPieceTaille() : -1,
                stockage.lire(locataire.getPieceCle()));
    }
}
