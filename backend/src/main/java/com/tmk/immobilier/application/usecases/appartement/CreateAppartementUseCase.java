package com.tmk.immobilier.application.usecases.appartement;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.domain.appartement.TypeLogement;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceAlreadyExistsException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class CreateAppartementUseCase {

    private final AppartementRepository appartementRepository;
    private final ImmeubleRepository immeubleRepository;

    @Transactional
    public Appartement execute(Long immeubleId, Appartement appartement) {
        Immeuble immeuble = immeubleRepository.findById(immeubleId)
                .orElseThrow(() -> ResourceNotFoundException.of("Immeuble", immeubleId));
        if (immeuble.estTerrain()) {
            throw new RegleMetierException("TERRAIN_SANS_LOCAUX",
                    "Un terrain se loue tel quel : on n'y ajoute pas de locaux.");
        }
        if (appartement.getType() == TypeLogement.TERRAIN) {
            throw new RegleMetierException("TYPE_TERRAIN_RESERVE",
                    "Le type Terrain est réservé aux biens de type terrain.");
        }
        String reference = appartement.getReference().trim();
        if (appartementRepository.existsByImmeubleIdAndReferenceIgnoreCase(immeubleId, reference)) {
            throw ResourceAlreadyExistsException.of("Logement", "référence", reference);
        }
        // Un logement neuf n'a pas de bail : il ne peut naître occupé.
        if (appartement.getStatut() == StatutAppartement.OCCUPE) {
            throw new RegleMetierException("STATUT_GERE_PAR_BAIL",
                    "Un logement est créé libre ou en travaux ; il devient occupé à la signature d'un bail.");
        }
        appartement.setId(null);
        appartement.setReference(reference);
        appartement.setImmeuble(immeuble);
        appartement.initializeDefaults();
        return appartementRepository.save(appartement);
    }
}
