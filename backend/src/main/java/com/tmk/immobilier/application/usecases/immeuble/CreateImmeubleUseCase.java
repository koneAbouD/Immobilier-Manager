package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.immeuble.OccupationImmeuble;
import com.tmk.immobilier.application.domain.immeuble.TypeBien;
import com.tmk.immobilier.application.exception.ResourceAlreadyExistsException;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class CreateImmeubleUseCase {

    private final ImmeubleRepository immeubleRepository;

    @Transactional
    public Immeuble execute(Immeuble immeuble) {
        String nom = immeuble.getNom().trim();
        if (immeubleRepository.existsByNomIgnoreCase(nom)) {
            throw ResourceAlreadyExistsException.of("Immeuble", "nom", nom);
        }
        immeuble.setId(null);
        immeuble.setNom(nom);
        if (immeuble.getType() == null) immeuble.setType(TypeBien.IMMEUBLE);
        Immeuble saved = immeubleRepository.save(immeuble);
        saved.setOccupation(OccupationImmeuble.VIDE);
        return saved;
    }
}
