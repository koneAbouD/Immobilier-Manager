package com.tmk.immobilier.application.usecases.locataire;

import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.ResourceAlreadyExistsException;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class CreateLocataireUseCase {

    private final LocataireRepository locataireRepository;

    @Transactional
    public Locataire execute(Locataire locataire) {
        String telephone = TelephoneNormalizer.normaliser(locataire.getTelephone());
        if (locataireRepository.existsByTelephone(telephone)) {
            throw ResourceAlreadyExistsException.of("Locataire", "téléphone", telephone);
        }
        locataire.setId(null);
        locataire.setTelephone(telephone);
        return locataireRepository.save(locataire);
    }
}
