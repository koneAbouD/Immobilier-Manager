package com.tmk.immobilier.application.usecases.journal;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.journal.ActionJournal;
import com.tmk.immobilier.application.domain.journal.EntreeJournal;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.application.ports.persistence.JournalActionsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

/** Consultation du journal, réservée aux administrateurs (voir SecurityConfig). */
@RequiredArgsConstructor
public class GetJournalActionsUseCase {

    private final JournalActionsRepository journal;

    @Transactional(readOnly = true)
    public PageResult<EntreeJournal> execute(TypeEntite type, ActionJournal action, String recherche,
                                             int page, int size) {
        return journal.findPage(type, action, recherche, page, Math.min(Math.max(size, 1), 100));
    }
}
