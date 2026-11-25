package com.tmk.immobilier.application.usecases.loyer;

import com.tmk.immobilier.application.domain.loyer.ResumeLoyersMois;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class ResumeLoyersTest {

    private final EcheanceLoyerRepository repo = mock(EcheanceLoyerRepository.class);
    private final GetEcheancesUseCase useCase = new GetEcheancesUseCase(repo);
    private final LocalDate novembre = LocalDate.of(2026, 11, 1);

    @Test
    void sansBienLeResumePorteSurTousLesBiens() {
        when(repo.sommeMontantDuPourPeriode(novembre)).thenReturn(new BigDecimal("900000"));
        when(repo.sommeMontantPayePourPeriode(novembre)).thenReturn(new BigDecimal("50000"));

        ResumeLoyersMois r = useCase.resumer(YearMonth.of(2026, 11), null);

        assertThat(r.reste()).isEqualByComparingTo("850000");
        assertThat(r.tauxRecouvrement()).isEqualTo(6);
        verify(repo, never()).sommeMontantDuPourPeriodeEtBien(any(), any());
    }

    @Test
    void avecUnBienLeResumeSeLimiteASesLogements() {
        when(repo.sommeMontantDuPourPeriodeEtBien(novembre, 2L)).thenReturn(new BigDecimal("400000"));
        when(repo.sommeMontantPayePourPeriodeEtBien(novembre, 2L)).thenReturn(new BigDecimal("400000"));

        ResumeLoyersMois r = useCase.resumer(YearMonth.of(2026, 11), 2L);

        assertThat(r.immeubleId()).isEqualTo(2L);
        assertThat(r.reste()).isEqualByComparingTo("0");
        assertThat(r.tauxRecouvrement()).isEqualTo(100);
    }

    @Test
    void unTropPercuNeDonnePasDeResteNegatif() {
        assertThat(new ResumeLoyersMois(novembre, null, new BigDecimal("100"), new BigDecimal("150")).reste())
                .isEqualByComparingTo("0");
    }
}
