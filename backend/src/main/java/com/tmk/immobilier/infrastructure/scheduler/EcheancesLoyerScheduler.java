package com.tmk.immobilier.infrastructure.scheduler;

import com.tmk.immobilier.application.usecases.loyer.GenererEcheancesUseCase;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.YearMonth;

/**
 * Émet chaque jour les loyers du mois courant pour les baux actifs. La
 * génération étant idempotente, un passage quotidien (plutôt que le 1er du
 * mois seulement) rattrape tout arrêt du serveur.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class EcheancesLoyerScheduler {

    private final GenererEcheancesUseCase genererEcheancesUseCase;

    @Scheduled(cron = "${app.scheduler.echeances-loyer-cron}", zone = "Africa/Abidjan")
    public void genererEcheancesDuMois() {
        int creees = genererEcheancesUseCase.execute(YearMonth.now());
        if (creees > 0) log.info("{} échéance(s) de loyer émise(s) pour {}", creees, YearMonth.now());
    }
}
