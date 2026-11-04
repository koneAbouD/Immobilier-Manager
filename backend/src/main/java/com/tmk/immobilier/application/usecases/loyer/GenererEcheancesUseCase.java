package com.tmk.immobilier.application.usecases.loyer;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Émet les loyers dus, mois par mois, jusqu'au mois donné inclus.
 *
 * <p>Idempotent : un mois déjà émis pour un bail n'est jamais recréé (contrainte
 * unique bail/période en base, et filtrage ici). Le scheduler peut donc
 * l'appeler chaque jour sans risque, et un trou — serveur arrêté un mois —
 * se comble au passage suivant.
 */
@RequiredArgsConstructor
public class GenererEcheancesUseCase {

    private final BailRepository bailRepository;
    private final EcheanceLoyerRepository echeanceLoyerRepository;

    /** @return nombre d'échéances créées, tous baux actifs confondus */
    @Transactional
    public int execute(YearMonth jusquA) {
        return bailRepository.findByStatut(StatutBail.ACTIF).stream()
                .mapToInt(bail -> executePourBail(bail, jusquA))
                .sum();
    }

    @Transactional
    public int executePourBail(Bail bail, YearMonth jusquA) {
        Set<LocalDate> dejaEmises = echeanceLoyerRepository.findByBailId(bail.getId()).stream()
                .map(EcheanceLoyer::getPeriode)
                .collect(Collectors.toSet());

        List<EcheanceLoyer> nouvelles = new ArrayList<>();
        for (YearMonth mois = YearMonth.from(bail.getDateDebut()); !mois.isAfter(jusquA); mois = mois.plusMonths(1)) {
            if (bail.couvre(mois) && !dejaEmises.contains(mois.atDay(1))) {
                nouvelles.add(EcheanceLoyer.pour(bail, mois));
            }
        }
        if (!nouvelles.isEmpty()) echeanceLoyerRepository.saveAll(nouvelles);
        return nouvelles.size();
    }
}
