package com.tmk.immobilier.interfaces.rest.loyer.dto.response;

import java.time.YearMonth;

public record GenerationEcheancesResponse(YearMonth jusquA, int nombreCreees) {
}
