package com.tmk.immobilier.application.usecases.locataire;

import com.tmk.immobilier.application.usecases.journal.JournalActions;
import com.tmk.immobilier.application.usecases.journal.InstantanesMetier;
import com.tmk.immobilier.application.domain.journal.Instantane;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.ResourceAlreadyExistsException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class UpdateLocataireUseCase {

    private final LocataireRepository locataireRepository;
    private final JournalActions journal;

    @Transactional
    public Locataire execute(Long id, Locataire modifications) {
        Locataire existant = locataireRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Locataire", id));
        Instantane avant = InstantanesMetier.de(existant);
        String telephone = TelephoneNormalizer.normaliser(modifications.getTelephone());
        if (locataireRepository.existsByTelephoneAndIdNot(telephone, id)) {
            throw ResourceAlreadyExistsException.of("Locataire", "téléphone", telephone);
        }
        modifications.setId(id);
        modifications.setTelephone(telephone);
        modifications.conserverPieceIdentiteDe(existant);
        Locataire enregistre = locataireRepository.save(modifications);
        journal.modification(TypeEntite.LOCATAIRE, id, modifications.nomComplet(), null,
                avant, InstantanesMetier.de(modifications));
        return enregistre;
    }
}
