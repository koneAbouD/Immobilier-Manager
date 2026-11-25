package com.tmk.immobilier.application.usecases.appartement;

import com.tmk.immobilier.application.usecases.journal.JournalActions;
import com.tmk.immobilier.application.usecases.journal.InstantanesMetier;
import com.tmk.immobilier.application.domain.journal.Instantane;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.commun.BlocageSuppression;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/** Supprime un logement saisi par erreur, tant qu'aucun bail ni intervention ne s'y rattache. */
@RequiredArgsConstructor
public class DeleteAppartementUseCase {

    private final AppartementRepository appartementRepository;
    private final BailRepository bailRepository;
    private final MaintenanceRepository maintenanceRepository;
    private final JournalActions journal;

    /** Ce qui empêche de supprimer le logement, vide s'il peut l'être. */
    @Transactional(readOnly = true)
    public Optional<BlocageSuppression> blocage(Long id) {
        appartementRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Logement", id));
        if (bailRepository.existsByAppartementId(id)) {
            return Optional.of(new BlocageSuppression("APPARTEMENT_AVEC_BAIL",
                    "Ce logement a un historique de baux : il ne peut pas être supprimé."));
        }
        if (maintenanceRepository.existsByAppartementId(id)) {
            return Optional.of(new BlocageSuppression("APPARTEMENT_AVEC_HISTORIQUE",
                    "Ce logement a un historique de maintenances : il ne peut pas être supprimé."));
        }
        return Optional.empty();
    }

    @Transactional
    public void execute(Long id) {
        blocage(id).ifPresent(b -> { throw b.enException(); });
        Appartement local = appartementRepository.findById(id).orElseThrow();
        journal.suppression(TypeEntite.LOCAL, id, local.getReference(), InstantanesMetier.contexte(local),
                InstantanesMetier.de(local));
        appartementRepository.deleteById(id);
    }
}
