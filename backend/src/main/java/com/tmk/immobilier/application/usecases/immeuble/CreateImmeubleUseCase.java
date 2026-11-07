package com.tmk.immobilier.application.usecases.immeuble;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.appartement.TypeLogement;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.immeuble.OccupationImmeuble;
import com.tmk.immobilier.application.domain.immeuble.TypeBien;
import com.tmk.immobilier.application.exception.ResourceAlreadyExistsException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * Crée un bien. Un terrain reçoit d'office son unique local, le terrain
 * lui-même, sur lequel se signent ses baux comme sur tout local.
 */
@RequiredArgsConstructor
public class CreateImmeubleUseCase {

    /** Référence du local qui représente un terrain. */
    public static final String REFERENCE_TERRAIN = "TERRAIN";

    private final ImmeubleRepository immeubleRepository;
    private final AppartementRepository appartementRepository;

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
        if (saved.estTerrain()) {
            Appartement terrain = Appartement.builder()
                    .immeuble(saved)
                    .reference(REFERENCE_TERRAIN)
                    .type(TypeLogement.TERRAIN)
                    // Le loyer se fixe à la signature du bail.
                    .loyerMensuel(BigDecimal.ZERO)
                    .build();
            terrain.initializeDefaults();
            appartementRepository.save(terrain);
            saved.setOccupation(new OccupationImmeuble(1, 0, 1));
        } else {
            saved.setOccupation(OccupationImmeuble.VIDE);
        }
        return saved;
    }
}
