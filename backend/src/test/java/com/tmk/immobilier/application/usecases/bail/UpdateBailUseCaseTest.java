package com.tmk.immobilier.application.usecases.bail;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.domain.loyer.StatutEcheance;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UpdateBailUseCaseTest {

    @Mock
    private BailRepository bailRepository;
    @Mock
    private EcheanceLoyerRepository echeanceLoyerRepository;
    @InjectMocks
    private UpdateBailUseCase useCase;

    private Bail bail;

    @BeforeEach
    void setUp() {
        bail = Bail.builder().id(3L).statut(StatutBail.ACTIF).dateDebut(LocalDate.of(2026, 12, 1))
                .loyerMensuel(new BigDecimal("100000")).moisAvance(0).creeLe(LocalDate.of(2026, 11, 24)).build();
        bail.initializeDefaults();
        bail.recalculerPremierMoisFacture();
        when(bailRepository.findById(3L)).thenReturn(Optional.of(bail));
    }

    private Bail modifications() {
        return Bail.builder().dateDebut(bail.getDateDebut()).moisAvance(bail.getMoisAvance())
                .premierMoisFacture(bail.getPremierMoisFacture()).build();
    }

    @Test
    void passerExterneAnnuleLesLoyersNonRegles() {
        bail.setCreeLe(LocalDate.now().minusDays(10));
        EcheanceLoyer emise = EcheanceLoyer.pour(bail, YearMonth.from(bail.getPremierMoisFacture()));
        when(echeanceLoyerRepository.findByBailId(3L)).thenReturn(List.of(emise));
        when(bailRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        Bail m = modifications();
        m.setExterne(true);
        m.setGestionnaireExterne(" Agence Horizon ");

        Bail maj = useCase.execute(3L, m);

        assertThat(maj.estExterne()).isTrue();
        assertThat(maj.getGestionnaireExterne()).isEqualTo("Agence Horizon");
        assertThat(emise.getStatut()).isEqualTo(StatutEcheance.ANNULEE);
        verify(echeanceLoyerRepository).saveAll(List.of(emise));
    }

    @Test
    void refusePasserExterneSiUnLoyerEstEncaisse() {
        bail.setCreeLe(LocalDate.now().minusDays(10));
        EcheanceLoyer emise = EcheanceLoyer.pour(bail, YearMonth.from(bail.getPremierMoisFacture()));
        emise.enregistrerPaiement(new BigDecimal("1000"));
        when(echeanceLoyerRepository.findByBailId(3L)).thenReturn(List.of(emise));
        Bail m = modifications();
        m.setExterne(true);

        assertThatThrownBy(() -> useCase.execute(3L, m)).hasMessageContaining("déjà été encaissés");
        verify(bailRepository, never()).save(any());
    }

    @Test
    void refuseDeChangerLeRecouvrementApres45Jours() {
        bail.setCreeLe(LocalDate.now().minusDays(46));
        when(echeanceLoyerRepository.findByBailId(3L)).thenReturn(List.of());
        Bail m = modifications();
        m.setExterne(true);

        assertThatThrownBy(() -> useCase.execute(3L, m)).hasMessageContaining("45 jours");
        verify(bailRepository, never()).save(any());
    }

    @Test
    void redevientInterneDansLeDelai() {
        bail.setCreeLe(LocalDate.now().minusDays(45));
        bail.setExterne(true);
        bail.setGestionnaireExterne("Agence Horizon");
        when(echeanceLoyerRepository.findByBailId(3L)).thenReturn(List.of());
        when(bailRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        Bail m = modifications();
        m.setExterne(false);

        Bail maj = useCase.execute(3L, m);

        assertThat(maj.estExterne()).isFalse();
        assertThat(maj.getGestionnaireExterne()).isNull();
    }

    @Test
    void sansLoyerEmisLAvanceRecalculeLePremierMois() {
        when(echeanceLoyerRepository.findByBailId(3L)).thenReturn(List.of());
        when(bailRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        Bail m = modifications();
        m.setMoisAvance(2);

        Bail maj = useCase.execute(3L, m);

        assertThat(maj.getPremierMoisFacture()).isEqualTo(LocalDate.of(2027, 2, 1));
    }

    @Test
    void unPremierMoisSaisiLEmporte() {
        when(echeanceLoyerRepository.findByBailId(3L)).thenReturn(List.of());
        when(bailRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        Bail m = modifications();
        m.setPremierMoisFacture(LocalDate.of(2027, 3, 15));

        assertThat(useCase.execute(3L, m).getPremierMoisFacture()).isEqualTo(LocalDate.of(2027, 3, 1));
    }

    @Test
    void refuseDeRepousserLaFacturationApresUnLoyerEmis() {
        when(echeanceLoyerRepository.findByBailId(3L))
                .thenReturn(List.of(EcheanceLoyer.pour(bail, YearMonth.of(2026, 12))));
        Bail m = modifications();
        m.setPremierMoisFacture(LocalDate.of(2027, 2, 1));

        assertThatThrownBy(() -> useCase.execute(3L, m)).hasMessageContaining("décembre 2026");
        verify(bailRepository, never()).save(any());
    }
}
