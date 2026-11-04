package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.immeuble.OccupationImmeuble;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@RequiredArgsConstructor
public class GetImmeublesUseCase {

    private final ImmeubleRepository immeubleRepository;
    private final AppartementRepository appartementRepository;

    /** Liste complète, pour les sélecteurs. */
    @Transactional(readOnly = true)
    public List<Immeuble> execute() {
        List<Immeuble> immeubles = immeubleRepository.findAll();
        enrichirOccupation(immeubles);
        return immeubles;
    }

    @Transactional(readOnly = true)
    public PageResult<Immeuble> executePage(String recherche, int page, int size) {
        PageResult<Immeuble> result = immeubleRepository.findPage(recherche, page, size);
        enrichirOccupation(result.content());
        return result;
    }

    /** Une seule requête d'agrégat pour toute la page, jamais une par immeuble. */
    private void enrichirOccupation(List<Immeuble> immeubles) {
        if (immeubles.isEmpty()) return;
        Map<Long, OccupationImmeuble> occupations = appartementRepository.occupationParImmeuble(
                immeubles.stream().map(Immeuble::getId).toList());
        immeubles.forEach(i -> i.setOccupation(occupations.getOrDefault(i.getId(), OccupationImmeuble.VIDE)));
    }
}
