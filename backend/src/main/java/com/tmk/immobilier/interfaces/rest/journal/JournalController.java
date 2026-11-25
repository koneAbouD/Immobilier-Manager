package com.tmk.immobilier.interfaces.rest.journal;

import com.tmk.immobilier.application.domain.journal.ActionJournal;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.application.usecases.journal.GetJournalActionsUseCase;
import com.tmk.immobilier.interfaces.rest.common.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/journal")
@RequiredArgsConstructor
@Tag(name = "Journal des actions", description = "Modifications et suppressions, réservé aux administrateurs")
public class JournalController {

    private final GetJournalActionsUseCase getJournalActionsUseCase;

    @GetMapping("/page")
    @Operation(summary = "Journal des actions",
            description = "Plus récentes d'abord ; recherche sur le nom, le rattachement et l'auteur")
    public PageResponse<EntreeJournalResponse> findPage(
            @RequestParam(required = false) TypeEntite type,
            @RequestParam(required = false) ActionJournal action,
            @RequestParam(required = false) String recherche,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getJournalActionsUseCase.execute(type, action, recherche, page, size)
                .map(EntreeJournalResponse::de));
    }
}
