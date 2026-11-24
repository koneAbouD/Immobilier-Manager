package com.tmk.immobilier.application.usecases.bail;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.StatutEcheance;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

/**
 * Révise les conditions d'un bail actif. Les nouvelles conditions valent pour
 * les échéances générées ensuite : celles déjà émises gardent leur montant,
 * elles ont pu être réglées sur cette base.
 *
 * <p>Premier mois facturé : recalculé si la date de début ou l'avance change
 * tant qu'aucun loyer n'est émis ; une valeur saisie l'emporte. Il ne peut pas
 * passer après un loyer déjà émis et non annulé.
 */
@RequiredArgsConstructor
public class UpdateBailUseCase {

    private static final DateTimeFormatter MOIS = DateTimeFormatter.ofPattern("MMMM yyyy", Locale.FRENCH);

    private final BailRepository bailRepository;
    private final EcheanceLoyerRepository echeanceLoyerRepository;

    @Transactional
    public Bail execute(Long id, Bail modifications) {
        Bail existant = bailRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Bail", id));
        if (!existant.estActif()) {
            throw new RegleMetierException("BAIL_NON_ACTIF", "Un bail résilié ne se modifie plus.");
        }
        LocalDate debutAvant = existant.getDateDebut();
        Integer avanceAvant = existant.getMoisAvance();
        LocalDate premierAvant = existant.getPremierMoisFacture();

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
        if (modifications.getMoisAvance() != null) existant.setMoisAvance(modifications.getMoisAvance());
        if (modifications.getJourEcheance() != null) existant.setJourEcheance(modifications.getJourEcheance());

        List<EcheanceLoyer> emises = echeanceLoyerRepository.findByBailId(id).stream()
                .filter(e -> e.getStatut() != StatutEcheance.ANNULEE)
                .toList();
        LocalDate premierSaisi = modifications.getPremierMoisFacture();
        if (premierSaisi != null && !YearMonth.from(premierSaisi).equals(YearMonth.from(premierAvant))) {
            existant.definirPremierMoisFacture(premierSaisi);
        } else if (emises.isEmpty()
                && (!existant.getDateDebut().equals(debutAvant) || !Objects.equals(existant.getMoisAvance(), avanceAvant))) {
            existant.recalculerPremierMoisFacture();
        }

        YearMonth premier = existant.premierMois();
        emises.stream()
                .map(e -> YearMonth.from(e.getPeriode()))
                .filter(periode -> periode.isBefore(premier))
                .min(YearMonth::compareTo)
                .ifPresent(periode -> {
                    throw new RegleMetierException("LOYERS_DEJA_EMIS",
                            "Le loyer de " + periode.format(MOIS) + " est déjà émis : annulez-le avant de faire "
                                    + "commencer la facturation en " + premier.format(MOIS) + ".");
                });

        existant.valider();
        return bailRepository.save(existant);
    }
}
