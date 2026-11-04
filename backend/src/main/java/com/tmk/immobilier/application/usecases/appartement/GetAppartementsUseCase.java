package com.tmk.immobilier.application.usecases.appartement;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class GetAppartementsUseCase {

    private final AppartementRepository appartementRepository;

    @Transactional(readOnly = true)
    public PageResult<Appartement> executePage(Long immeubleId, StatutAppartement statut, String recherche,
                                               int page, int size) {
        return appartementRepository.findPage(immeubleId, statut, recherche, page, size);
    }
}
