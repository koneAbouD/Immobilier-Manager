package com.tmk.immobilier.interfaces.rest.tableaubord;

import com.tmk.immobilier.application.usecases.tableaubord.GetTableauBordUseCase;
import com.tmk.immobilier.interfaces.rest.tableaubord.dto.TableauBordResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.YearMonth;

@RestController
@RequestMapping("/api/tableau-bord")
@RequiredArgsConstructor
@Tag(name = "Tableau de bord")
public class TableauBordController {

    private final GetTableauBordUseCase getTableauBordUseCase;

    @GetMapping
    public TableauBordResponse get(
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM") YearMonth periode) {
        return TableauBordResponse.from(getTableauBordUseCase.execute(periode));
    }
}
