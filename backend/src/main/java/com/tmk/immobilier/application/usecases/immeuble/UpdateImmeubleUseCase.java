package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.exception.RegleMetierException;
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
        if (modifications.getType() != null) {
            // Un terrain porte son local automatique, un immeuble ses locaux saisis :
            // passer de l'un à l'autre les rendrait incohérents.
            if (modifications.estTerrain() != existant.estTerrain()) {
                throw new RegleMetierException("TYPE_TERRAIN_FIGE",
                        "Le type Terrain se choisit à la création du bien et ne change plus.");
            }
            existant.setType(modifications.getType());
        }
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
