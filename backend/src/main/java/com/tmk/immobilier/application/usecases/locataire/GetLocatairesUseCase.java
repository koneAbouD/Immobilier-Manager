package com.tmk.immobilier.application.usecases.locataire;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class GetLocatairesUseCase {

    private final LocataireRepository locataireRepository;

    @Transactional(readOnly = true)
    public PageResult<Locataire> executePage(String recherche, int page, int size) {
        return locataireRepository.findPage(recherche, page, size);
    }
}
