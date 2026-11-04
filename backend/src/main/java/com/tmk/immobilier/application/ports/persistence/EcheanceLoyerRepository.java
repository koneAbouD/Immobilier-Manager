package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.StatutEcheance;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface EcheanceLoyerRepository {

    EcheanceLoyer save(EcheanceLoyer echeance);

    List<EcheanceLoyer> saveAll(List<EcheanceLoyer> echeances);

    Optional<EcheanceLoyer> findById(Long id);

    /**
     * @param periode  premier jour du mois ; ignoré s'il est nul
     * @param aEncaisser si vrai, seules les échéances non soldées (à payer ou partielles)
     * @param enRetard   si vrai, seules les échéances échues non soldées au {@code aujourdhui} donné
     */
    PageResult<EcheanceLoyer> findPage(Long bailId, Long locataireId, Long immeubleId, LocalDate periode,
                                       StatutEcheance statut, boolean aEncaisser, boolean enRetard,
                                       LocalDate aujourdhui,
                                       int page, int size);

    List<EcheanceLoyer> findByBailId(Long bailId);

    boolean existsByBailIdAndPeriode(Long bailId, LocalDate periode);

    /** Total dû des échéances du mois, hors annulées. */
    BigDecimal sommeMontantDuPourPeriode(LocalDate periode);

    /** Total payé des échéances du mois, hors annulées. */
    BigDecimal sommeMontantPayePourPeriode(LocalDate periode);

    /** Reste dû cumulé des échéances échues avant {@code aujourdhui} et non soldées. */
    BigDecimal sommeImpayesAu(LocalDate aujourdhui);

    long countEnRetardAu(LocalDate aujourdhui);
}
