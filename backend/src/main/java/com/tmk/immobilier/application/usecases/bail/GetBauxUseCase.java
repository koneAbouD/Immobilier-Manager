package com.tmk.immobilier.application.usecases.bail;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class GetBauxUseCase {

    private final BailRepository bailRepository;

    @Transactional(readOnly = true)
    public PageResult<Bail> executePage(Long appartementId, Long locataireId, Long immeubleId, StatutBail statut,
                                        String recherche, int page, int size) {
        return bailRepository.findPage(appartementId, locataireId, immeubleId, statut, recherche, page, size);
    }
}
