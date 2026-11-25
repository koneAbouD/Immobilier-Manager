package com.tmk.immobilier.application.usecases.locataire;

import com.tmk.immobilier.application.usecases.journal.JournalActions;
import com.tmk.immobilier.application.usecases.journal.InstantanesMetier;
import com.tmk.immobilier.application.domain.journal.Instantane;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.application.domain.commun.BlocageSuppression;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@RequiredArgsConstructor
public class DeleteLocataireUseCase {

    private final LocataireRepository locataireRepository;
    private final BailRepository bailRepository;
    private final JournalActions journal;

    /** Ce qui empêche de supprimer le locataire, vide s'il peut l'être. */
    @Transactional(readOnly = true)
    public Optional<BlocageSuppression> blocage(Long id) {
        locataireRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Locataire", id));
        if (bailRepository.existsByLocataireId(id)) {
            return Optional.of(new BlocageSuppression("LOCATAIRE_AVEC_BAIL",
                    "Ce locataire a un historique de baux et de paiements : il ne peut pas être supprimé."));
        }
        return Optional.empty();
    }

    @Transactional
    public void execute(Long id) {
        blocage(id).ifPresent(b -> { throw b.enException(); });
        Locataire locataire = locataireRepository.findById(id).orElseThrow();
        journal.suppression(TypeEntite.LOCATAIRE, id, locataire.nomComplet(), null, InstantanesMetier.de(locataire));
        locataireRepository.deleteById(id);
    }
}
