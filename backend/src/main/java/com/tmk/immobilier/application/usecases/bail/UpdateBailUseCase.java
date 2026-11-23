package com.tmk.immobilier.application.usecases.bail;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

/**
 * Révise les conditions d'un bail actif. Les nouvelles conditions valent pour
 * les échéances générées ensuite : celles déjà émises gardent leur montant,
 * elles ont pu être réglées sur cette base.
 */
@RequiredArgsConstructor
public class UpdateBailUseCase {

    private final BailRepository bailRepository;

    @Transactional
    public Bail execute(Long id, Bail modifications) {
        Bail existant = bailRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Bail", id));
        if (!existant.estActif()) {
            throw new RegleMetierException("BAIL_NON_ACTIF", "Un bail résilié ne se modifie plus.");
        }
        if (modifications.getDateDebut() != null) existant.setDateDebut(modifications.getDateDebut());
        existant.setDateFin(modifications.getDateFin());
        if (modifications.getLoyerMensuel() != null) existant.setLoyerMensuel(modifications.getLoyerMensuel());
        if (modifications.getCharges() != null) existant.setCharges(modifications.getCharges());
        if (modifications.getDepotGarantie() != null) existant.setDepotGarantie(modifications.getDepotGarantie());
        if (modifications.getMoisCaution() != null) {
            // Recalculé seulement sur demande : une révision du loyer ne touche pas
            // à la caution déjà versée.
            existant.setMoisCaution(modifications.getMoisCaution());
            existant.appliquerCaution();
        } else if (modifications.getDepotGarantie() != null) {
            // Montant saisi librement : il ne dérive plus d'un nombre de mois.
            existant.setMoisCaution(null);
        }
        if (modifications.getJourEcheance() != null) existant.setJourEcheance(modifications.getJourEcheance());
        existant.valider();
        return bailRepository.save(existant);
    }
}
