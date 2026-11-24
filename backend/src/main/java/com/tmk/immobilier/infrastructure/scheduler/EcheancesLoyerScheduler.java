package com.tmk.immobilier.infrastructure.scheduler;

import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import com.tmk.immobilier.application.usecases.loyer.GenererEcheancesUseCase;
import com.tmk.immobilier.infrastructure.organisation.ContexteOrganisation;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;


/**
 * Émet chaque jour les loyers dus des baux actifs : celui du mois courant à
 * partir du 25, les mois précédents sinon. La génération étant idempotente, un
 * passage quotidien rattrape tout arrêt du serveur.
 *
 * <p>Les organisations sont traitées une à une, chacune dans son propre
 * contexte et sa propre transaction : l'échec de l'une n'empêche pas l'émission
 * des autres. Les organisations en lecture seule continuent d'émettre — les
 * loyers restent dus, que l'abonnement soit à jour ou non.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class EcheancesLoyerScheduler {

    private final GenererEcheancesUseCase genererEcheancesUseCase;
    private final OrganisationRepository organisationRepository;

    @Scheduled(cron = "${app.scheduler.echeances-loyer-cron}", zone = "Africa/Abidjan")
    public void genererEcheancesDuMois() {
        int total = 0;
        int echecs = 0;
        for (Long organisationId : organisationRepository.findIdsActives()) {
            try {
                int creees = ContexteOrganisation.executerPour(organisationId, genererEcheancesUseCase::executeAutomatique);
                if (creees > 0) log.info("Organisation {} : {} échéance(s) de loyer émise(s)", organisationId, creees);
                total += creees;
            } catch (RuntimeException e) {
                echecs++;
                log.error("Émission des loyers impossible pour l'organisation {}", organisationId, e);
            }
        }
        if (total > 0 || echecs > 0) log.info("Émission des loyers : {} échéance(s), {} organisation(s) en échec", total, echecs);
    }
}
