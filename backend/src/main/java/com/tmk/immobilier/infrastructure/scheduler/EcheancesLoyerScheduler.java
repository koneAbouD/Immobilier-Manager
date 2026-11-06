package com.tmk.immobilier.infrastructure.scheduler;

import com.tmk.immobilier.application.usecases.loyer.GenererEcheancesUseCase;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;


/**
 * Émet chaque jour les loyers dus des baux actifs : celui du mois courant à
 * partir du 25, les mois précédents sinon. La génération étant idempotente, un
 * passage quotidien rattrape tout arrêt du serveur.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class EcheancesLoyerScheduler {

    private final GenererEcheancesUseCase genererEcheancesUseCase;

    @Scheduled(cron = "${app.scheduler.echeances-loyer-cron}", zone = "Africa/Abidjan")
    public void genererEcheancesDuMois() {
        int creees = genererEcheancesUseCase.executeAutomatique();
        if (creees > 0) log.info("{} échéance(s) de loyer émise(s)", creees);
    }
}
