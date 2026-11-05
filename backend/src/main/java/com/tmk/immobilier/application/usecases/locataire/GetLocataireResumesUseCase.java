package com.tmk.immobilier.application.usecases.locataire;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.locataire.ComptesSituations;
import com.tmk.immobilier.application.domain.locataire.LocataireResume;
import com.tmk.immobilier.application.domain.locataire.SituationLocataire;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

/** Liste des locataires avec leur logement et l'état de leurs loyers au jour courant. */
@RequiredArgsConstructor
public class GetLocataireResumesUseCase {

    private final LocataireRepository locataireRepository;

    @Transactional(readOnly = true)
    public PageResult<LocataireResume> executePage(String recherche, SituationLocataire situation, int page, int size) {
        return locataireRepository.findResumes(recherche, situation, LocalDate.now(), page, size);
    }

    @Transactional(readOnly = true)
    public ComptesSituations compter(String recherche) {
        return locataireRepository.compterSituations(recherche, LocalDate.now());
    }
}
