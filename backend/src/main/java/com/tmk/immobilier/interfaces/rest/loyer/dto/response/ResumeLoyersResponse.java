package com.tmk.immobilier.interfaces.rest.loyer.dto.response;

import com.tmk.immobilier.application.domain.loyer.ResumeLoyersMois;

import java.math.BigDecimal;
import java.time.LocalDate;

public record ResumeLoyersResponse(
        LocalDate periode,
        Long immeubleId,
        BigDecimal attendu,
        BigDecimal encaisse,
        BigDecimal reste,
        int tauxRecouvrement
) {
    public static ResumeLoyersResponse from(ResumeLoyersMois r) {
        return new ResumeLoyersResponse(r.periode(), r.immeubleId(), r.attendu(), r.encaisse(), r.reste(),
                r.tauxRecouvrement());
    }
}
