package com.tmk.immobilier.application.usecases.loyer;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.loyer.PaiementLoyer;
import com.tmk.immobilier.application.ports.persistence.PaiementLoyerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@RequiredArgsConstructor
public class GetPaiementsUseCase {

    private final PaiementLoyerRepository paiementLoyerRepository;

    @Transactional(readOnly = true)
    public PageResult<PaiementLoyer> executePage(Long bailId, Long locataireId, LocalDate dateDebut,
                                                 LocalDate dateFin, Boolean annule, int page, int size) {
        return paiementLoyerRepository.findPage(bailId, locataireId, dateDebut, dateFin, annule, page, size);
    }

    @Transactional(readOnly = true)
    public List<PaiementLoyer> executeParEcheance(Long echeanceId) {
        return paiementLoyerRepository.findByEcheanceId(echeanceId);
    }
}
