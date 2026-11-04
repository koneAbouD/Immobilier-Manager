package com.tmk.immobilier.application.usecases.locataire;

import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class GetLocataireByIdUseCase {

    private final LocataireRepository locataireRepository;

    @Transactional(readOnly = true)
    public Locataire execute(Long id) {
        return locataireRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Locataire", id));
    }
}
