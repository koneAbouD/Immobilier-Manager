package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.immeuble.OccupationImmeuble;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@RequiredArgsConstructor
public class GetImmeubleByIdUseCase {

    private final ImmeubleRepository immeubleRepository;
    private final AppartementRepository appartementRepository;

    @Transactional(readOnly = true)
    public Immeuble execute(Long id) {
        Immeuble immeuble = immeubleRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Immeuble", id));
        immeuble.setOccupation(appartementRepository.occupationParImmeuble(List.of(id))
                .getOrDefault(id, OccupationImmeuble.VIDE));
        return immeuble;
    }
}
