package com.tmk.immobilier.application.usecases.appartement;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.exception.ResourceAlreadyExistsException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * Met à jour la fiche d'un logement. L'immeuble de rattachement ne change pas
 * (un logement ne déménage pas), et le statut OCCUPE reste l'affaire des baux.
 * Modifier le loyer affiché ne touche pas aux baux en cours.
 */
@RequiredArgsConstructor
public class UpdateAppartementUseCase {

    private final AppartementRepository appartementRepository;

    @Transactional
    public Appartement execute(Long id, Appartement modifications) {
        Appartement existant = appartementRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Logement", id));
        String reference = modifications.getReference().trim();
        Long immeubleId = existant.getImmeuble().getId();
        if (appartementRepository.existsByImmeubleIdAndReferenceIgnoreCaseAndIdNot(immeubleId, reference, id)) {
            throw ResourceAlreadyExistsException.of("Logement", "référence", reference);
        }
        existant.setReference(reference);
        existant.setEtage(modifications.getEtage());
        existant.setType(modifications.getType());
        existant.setSuperficie(modifications.getSuperficie());
        existant.setNombrePieces(modifications.getNombrePieces());
        existant.setLoyerMensuel(modifications.getLoyerMensuel());
        existant.setCharges(modifications.getCharges() != null ? modifications.getCharges() : BigDecimal.ZERO);
        existant.setDescription(modifications.getDescription());
        existant.changerStatutManuellement(modifications.getStatut());
        return appartementRepository.save(existant);
    }
}
