package com.tmk.immobilier.application.usecases.locataire;

import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class DeleteLocataireUseCase {

    private final LocataireRepository locataireRepository;
    private final BailRepository bailRepository;

    @Transactional
    public void execute(Long id) {
        locataireRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Locataire", id));
        if (bailRepository.existsByLocataireId(id)) {
            throw new RegleMetierException("LOCATAIRE_AVEC_BAIL",
                    "Ce locataire a un historique de baux et de paiements : il ne peut pas être supprimé.");
        }
        locataireRepository.deleteById(id);
    }
}
