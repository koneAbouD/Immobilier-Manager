package com.tmk.immobilier.application.usecases.loyer;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.StatutEcheance;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;

@RequiredArgsConstructor
public class GetEcheancesUseCase {

    private final EcheanceLoyerRepository echeanceLoyerRepository;

    @Transactional(readOnly = true)
    public PageResult<EcheanceLoyer> executePage(Long bailId, Long locataireId, Long immeubleId, YearMonth periode,
                                                 StatutEcheance statut, boolean aEncaisser, boolean enRetard,
                                                 int page, int size) {
        return echeanceLoyerRepository.findPage(bailId, locataireId, immeubleId,
                periode != null ? periode.atDay(1) : null, statut, aEncaisser, enRetard, LocalDate.now(),
                page, size);
    }

    @Transactional(readOnly = true)
    public EcheanceLoyer executeById(Long id) {
        return echeanceLoyerRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Échéance de loyer", id));
    }
}
