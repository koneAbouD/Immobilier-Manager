package com.tmk.immobilier.application.usecases.loyer;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.loyer.EcheanceLoyer;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GenererEcheancesUseCaseTest {

    @Mock
    private BailRepository bailRepository;
    @Mock
    private EcheanceLoyerRepository echeanceLoyerRepository;
    @InjectMocks
    private GenererEcheancesUseCase useCase;

    private Bail bail() {
        Bail bail = Bail.builder().id(7L).dateDebut(LocalDate.of(2026, 7, 20))
                .loyerMensuel(new BigDecimal("80000")).build();
        bail.initializeDefaults();
        return bail;
    }

    @Test
    @SuppressWarnings("unchecked")
    void rattrapeTousLesMoisDepuisLeDebutDuBail() {
        when(echeanceLoyerRepository.findByBailId(7L)).thenReturn(List.of());

        int creees = useCase.executePourBail(bail(), YearMonth.of(2026, 10));

        ArgumentCaptor<List<EcheanceLoyer>> captor = ArgumentCaptor.forClass(List.class);
        verify(echeanceLoyerRepository).saveAll(captor.capture());
        assertThat(creees).isEqualTo(4);
        assertThat(captor.getValue()).extracting(EcheanceLoyer::getPeriode).containsExactly(
                LocalDate.of(2026, 7, 1), LocalDate.of(2026, 8, 1),
                LocalDate.of(2026, 9, 1), LocalDate.of(2026, 10, 1));
        assertThat(captor.getValue().get(0).getDateEcheance()).isEqualTo(LocalDate.of(2026, 7, 5));
    }

    @Test
    void estIdempotente() {
        Bail bail = bail();
        when(echeanceLoyerRepository.findByBailId(7L)).thenReturn(List.of(
                EcheanceLoyer.pour(bail, YearMonth.of(2026, 7)),
                EcheanceLoyer.pour(bail, YearMonth.of(2026, 8))));

        int creees = useCase.executePourBail(bail, YearMonth.of(2026, 8));

        assertThat(creees).isZero();
        verify(echeanceLoyerRepository, never()).saveAll(any());
    }
}
