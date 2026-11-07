package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.exception.ResourceAlreadyExistsException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class UpdateImmeubleUseCase {

    private final ImmeubleRepository immeubleRepository;

    @Transactional
    public Immeuble execute(Long id, Immeuble modifications) {
        Immeuble existant = immeubleRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Immeuble", id));
        String nom = modifications.getNom().trim();
        if (immeubleRepository.existsByNomIgnoreCaseAndIdNot(nom, id)) {
            throw ResourceAlreadyExistsException.of("Immeuble", "nom", nom);
        }
        existant.setNom(nom);
        if (modifications.getType() != null) existant.setType(modifications.getType());
        existant.setAdresse(modifications.getAdresse());
        existant.setLatitude(modifications.getLatitude());
        existant.setLongitude(modifications.getLongitude());
        existant.setCommune(modifications.getCommune());
        existant.setVille(modifications.getVille());
        existant.setNombreEtages(modifications.getNombreEtages());
        existant.setAnneeConstruction(modifications.getAnneeConstruction());
        existant.setDescription(modifications.getDescription());
        return immeubleRepository.save(existant);
    }
}
