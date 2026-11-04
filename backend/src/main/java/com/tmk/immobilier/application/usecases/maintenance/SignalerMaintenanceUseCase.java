package com.tmk.immobilier.application.usecases.maintenance;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.immeuble.Immeuble;
import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

/**
 * Enregistre une demande d'intervention. Si un logement est désigné, il doit
 * appartenir à l'immeuble indiqué ; sans immeuble, celui du logement est repris.
 */
@RequiredArgsConstructor
public class SignalerMaintenanceUseCase {

    private final MaintenanceRepository maintenanceRepository;
    private final ImmeubleRepository immeubleRepository;
    private final AppartementRepository appartementRepository;

    @Transactional
    public Maintenance execute(Long immeubleId, Long appartementId, Maintenance maintenance) {
        MaintenanceRattachement.rattacher(maintenance, immeubleId, appartementId,
                immeubleRepository, appartementRepository);
        maintenance.setId(null);
        maintenance.setStatut(null);
        maintenance.initializeDefaults();
        return maintenanceRepository.save(maintenance);
    }
}

/** Résolution commune de l'immeuble et du logement d'une intervention. */
final class MaintenanceRattachement {

    private MaintenanceRattachement() {
    }

    static void rattacher(Maintenance maintenance, Long immeubleId, Long appartementId,
                          ImmeubleRepository immeubleRepository, AppartementRepository appartementRepository) {
        Appartement appartement = null;
        if (appartementId != null) {
            appartement = appartementRepository.findById(appartementId)
                    .orElseThrow(() -> ResourceNotFoundException.of("Logement", appartementId));
        }
        Long idImmeuble = immeubleId != null ? immeubleId
                : appartement != null ? appartement.getImmeuble().getId() : null;
        if (idImmeuble == null) {
            throw new RegleMetierException("RATTACHEMENT_OBLIGATOIRE",
                    "Indiquez l'immeuble ou le logement concerné par l'intervention.");
        }
        Immeuble immeuble = immeubleRepository.findById(idImmeuble)
                .orElseThrow(() -> ResourceNotFoundException.of("Immeuble", idImmeuble));
        if (appartement != null && !appartement.getImmeuble().getId().equals(immeuble.getId())) {
            throw new RegleMetierException("LOGEMENT_HORS_IMMEUBLE",
                    "Le logement " + appartement.getReference() + " n'appartient pas à l'immeuble " + immeuble.getNom() + ".");
        }
        maintenance.setImmeuble(immeuble);
        maintenance.setAppartement(appartement);
    }
}
