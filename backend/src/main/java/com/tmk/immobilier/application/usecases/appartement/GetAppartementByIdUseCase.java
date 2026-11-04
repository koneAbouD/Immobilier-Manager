package com.tmk.immobilier.application.usecases.appartement;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class GetAppartementByIdUseCase {

    private final AppartementRepository appartementRepository;

    @Transactional(readOnly = true)
    public Appartement execute(Long id) {
        return appartementRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Logement", id));
    }
}
