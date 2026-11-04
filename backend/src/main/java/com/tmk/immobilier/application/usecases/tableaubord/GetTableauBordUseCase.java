package com.tmk.immobilier.application.usecases.tableaubord;

import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.domain.maintenance.PrioriteMaintenance;
import com.tmk.immobilier.application.domain.maintenance.StatutMaintenance;
import com.tmk.immobilier.application.domain.tableaubord.TableauBord;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

@RequiredArgsConstructor
public class GetTableauBordUseCase {

    private static final List<StatutMaintenance> OUVERTES =
            List.of(StatutMaintenance.SIGNALEE, StatutMaintenance.PLANIFIEE, StatutMaintenance.EN_COURS);

    private final ImmeubleRepository immeubleRepository;
    private final AppartementRepository appartementRepository;
    private final BailRepository bailRepository;
    private final EcheanceLoyerRepository echeanceLoyerRepository;
    private final MaintenanceRepository maintenanceRepository;

    @Transactional(readOnly = true)
    public TableauBord execute(YearMonth mois) {
        LocalDate periode = (mois != null ? mois : YearMonth.now()).atDay(1);
        LocalDate aujourdhui = LocalDate.now();
        return new TableauBord(
                periode,
                immeubleRepository.count(),
                appartementRepository.count(),
                appartementRepository.countByStatut(StatutAppartement.OCCUPE),
                bailRepository.countLocatairesActifs(),
                echeanceLoyerRepository.sommeMontantDuPourPeriode(periode),
                echeanceLoyerRepository.sommeMontantPayePourPeriode(periode),
                echeanceLoyerRepository.sommeImpayesAu(aujourdhui),
                echeanceLoyerRepository.countEnRetardAu(aujourdhui),
                maintenanceRepository.countByStatutIn(OUVERTES),
                maintenanceRepository.countByStatutInAndPriorite(OUVERTES, PrioriteMaintenance.URGENTE)
        );
    }
}
