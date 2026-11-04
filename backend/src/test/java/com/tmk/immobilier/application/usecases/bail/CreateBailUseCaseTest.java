package com.tmk.immobilier.application.usecases.bail;

import com.tmk.immobilier.application.domain.appartement.Appartement;
import com.tmk.immobilier.application.domain.appartement.StatutAppartement;
import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.domain.bail.StatutBail;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import com.tmk.immobilier.application.usecases.loyer.GenererEcheancesUseCase;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CreateBailUseCaseTest {

    @Mock
    private BailRepository bailRepository;
    @Mock
    private AppartementRepository appartementRepository;
    @Mock
    private LocataireRepository locataireRepository;
    @Mock
    private GenererEcheancesUseCase genererEcheancesUseCase;
    @InjectMocks
    private CreateBailUseCase useCase;

    private Appartement appartement(StatutAppartement statut) {
        return Appartement.builder().id(1L).reference("A1").statut(statut)
                .loyerMensuel(new BigDecimal("120000")).charges(new BigDecimal("5000")).build();
    }

    @Test
    void signeLeBailOccupeLeLogementEtEmetLesLoyers() {
        Appartement appartement = appartement(StatutAppartement.LIBRE);
        when(appartementRepository.findById(1L)).thenReturn(Optional.of(appartement));
        when(locataireRepository.findById(2L)).thenReturn(Optional.of(Locataire.builder().id(2L).build()));
        when(bailRepository.existsByAppartementIdAndStatut(1L, StatutBail.ACTIF)).thenReturn(false);
        when(bailRepository.save(any())).thenAnswer(inv -> {
            Bail b = inv.getArgument(0);
            if (b.getId() == null) b.setId(42L);
            return b;
        });

        Bail bail = useCase.execute(1L, 2L, Bail.builder().dateDebut(LocalDate.of(2026, 9, 1)).build());

        assertThat(appartement.getStatut()).isEqualTo(StatutAppartement.OCCUPE);
        assertThat(bail.getReference()).isEqualTo("BAIL-00042");
        // Sans conditions propres, le bail reprend celles du logement.
        assertThat(bail.montantMensuel()).isEqualByComparingTo("125000");
        verify(genererEcheancesUseCase).executePourBail(eq(bail), eq(YearMonth.now()));
    }

    @Test
    void refuseUnLogementDejaLoue() {
        when(appartementRepository.findById(1L)).thenReturn(Optional.of(appartement(StatutAppartement.OCCUPE)));
        when(locataireRepository.findById(2L)).thenReturn(Optional.of(Locataire.builder().id(2L).build()));
        when(bailRepository.existsByAppartementIdAndStatut(1L, StatutBail.ACTIF)).thenReturn(true);

        assertThatThrownBy(() -> useCase.execute(1L, 2L, Bail.builder().dateDebut(LocalDate.now()).build()))
                .isInstanceOf(RegleMetierException.class)
                .hasMessageContaining("déjà un bail actif");
        verify(bailRepository, never()).save(any());
    }

    @Test
    void refuseUnLogementEnTravaux() {
        when(appartementRepository.findById(1L)).thenReturn(Optional.of(appartement(StatutAppartement.EN_TRAVAUX)));
        when(locataireRepository.findById(2L)).thenReturn(Optional.of(Locataire.builder().id(2L).build()));

        assertThatThrownBy(() -> useCase.execute(1L, 2L, Bail.builder().dateDebut(LocalDate.now()).build()))
                .isInstanceOf(RegleMetierException.class);
        verify(bailRepository, never()).save(any());
    }
}
