package com.tmk.immobilier.application.usecases.loyer;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
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
 * <p>Émission automatique : le loyer d'un mois n'est émis qu'à partir du
 * {@value #JOUR_EMISSION} de ce mois ; avant, seuls les mois précédents le
 * sont. Les mois suivants se créent à la main, pour un bail ou pour tous,
 * jusqu'à {@value #MOIS_ANTICIPATION_MAX} mois d'avance.
 *
 * <p>Idempotent : un mois déjà émis pour un bail n'est jamais recréé (contrainte
 * unique bail/période en base, et filtrage ici). Le scheduler peut donc
 * l'appeler chaque jour sans risque, et un trou — serveur arrêté un mois —
 * se comble au passage suivant.
 */
@RequiredArgsConstructor
public class GenererEcheancesUseCase {

    /** Jour du mois à partir duquel le loyer du mois est émis automatiquement. */
    public static final int JOUR_EMISSION = 25;

    /** Avance maximale d'une création manuelle, en mois. */
    public static final int MOIS_ANTICIPATION_MAX = 12;

    private final BailRepository bailRepository;
    private final EcheanceLoyerRepository echeanceLoyerRepository;

    /** Dernier mois émis automatiquement au jour donné : le mois courant à partir du 25, sinon le précédent. */
    public static YearMonth dernierMoisEmis(LocalDate jour) {
        YearMonth mois = YearMonth.from(jour);
        return jour.getDayOfMonth() >= JOUR_EMISSION ? mois : mois.minusMonths(1);
    }

    /** Émission automatique (scheduler) : comble les mois manquants jusqu'au dernier mois émissible. */
    @Transactional
    public int executeAutomatique() {
        return execute(dernierMoisEmis(LocalDate.now()));
    }

    /**
     * Création manuelle jusqu'au mois donné, pour un bail ou pour tous les baux
     * actifs ([bailId] nul).
     */
    @Transactional
    public int executeManuelle(Long bailId, YearMonth jusquA) {
        YearMonth limite = YearMonth.now().plusMonths(MOIS_ANTICIPATION_MAX);
        if (jusquA.isAfter(limite)) {
            throw new RegleMetierException("MOIS_TROP_LOINTAIN",
                    "Les loyers se créent au plus " + MOIS_ANTICIPATION_MAX + " mois à l'avance (jusqu'à " + limite + ").");
        }
        if (bailId == null) return execute(jusquA);
        Bail bail = bailRepository.findById(bailId).orElseThrow(() -> ResourceNotFoundException.of("Bail", bailId));
        if (!bail.estActif()) {
            throw new RegleMetierException("BAIL_NON_ACTIF", "Un bail résilié n'émet plus de loyers.");
        }
        return executePourBail(bail, jusquA);
    }

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
