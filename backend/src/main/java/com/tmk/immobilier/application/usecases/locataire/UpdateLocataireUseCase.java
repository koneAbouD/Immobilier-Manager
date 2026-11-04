package com.tmk.immobilier.application.usecases.locataire;

import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.ResourceAlreadyExistsException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class UpdateLocataireUseCase {

    private final LocataireRepository locataireRepository;

    @Transactional
    public Locataire execute(Long id, Locataire modifications) {
        locataireRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Locataire", id));
        String telephone = TelephoneNormalizer.normaliser(modifications.getTelephone());
        if (locataireRepository.existsByTelephoneAndIdNot(telephone, id)) {
            throw ResourceAlreadyExistsException.of("Locataire", "téléphone", telephone);
        }
        modifications.setId(id);
        modifications.setTelephone(telephone);
        return locataireRepository.save(modifications);
    }
}
