package com.tmk.immobilier.application.usecases.bail;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.StatutEcheance;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import com.tmk.immobilier.application.ports.security.AuteurCourantPort;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

/**
 * Fin d'un bail : le logement redevient libre, et les loyers des mois
 * postérieurs à la résiliation, déjà émis mais jamais payés, sont annulés.
 * Le mois de la résiliation reste dû ; les échéances antérieures impayées
 * aussi — la dette du locataire ne s'éteint pas avec son départ.
 */
@RequiredArgsConstructor
public class ResilierBailUseCase {

    private final BailRepository bailRepository;
    private final AppartementRepository appartementRepository;
    private final EcheanceLoyerRepository echeanceLoyerRepository;
    private final AuteurCourantPort auteurCourant;

    @Transactional
    public Bail execute(Long id, LocalDate dateResiliation, String motif) {
        Bail bail = bailRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Bail", id));
        bail.resilier(dateResiliation, motif, auteurCourant.auteur());

        Appartement appartement = bail.getAppartement();
        appartement.liberer();
        appartementRepository.save(appartement);

        YearMonth moisResiliation = YearMonth.from(bail.getDateResiliation());
        List<EcheanceLoyer> aAnnuler = echeanceLoyerRepository.findByBailId(id).stream()
                .filter(e -> YearMonth.from(e.getPeriode()).isAfter(moisResiliation))
                .filter(e -> e.getStatut() == StatutEcheance.A_PAYER)
                .toList();
        aAnnuler.forEach(EcheanceLoyer::annuler);
        echeanceLoyerRepository.saveAll(aAnnuler);

        return bailRepository.save(bail);
    }
}
